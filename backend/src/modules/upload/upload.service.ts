import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CloudinaryService } from './cloudinary.service';
import { ImageProcessorService } from './utils/image-processor.service';
import { CLOUDINARY_FOLDERS } from './constants/upload.constants';

@Injectable()
export class UploadService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService,
    private imageProcessor: ImageProcessorService,
  ) {}

  private ensureCloudinary() {
    if (!this.cloudinary.isConfigured()) {
      throw new BadRequestException(
        'Image upload service is not configured. Set CLOUDINARY_* env vars.',
      );
    }
  }

  async uploadProductImages(
    files: Express.Multer.File[],
    productId?: string,
    altText?: string,
  ) {
    this.ensureCloudinary();
    if (!files?.length) {
      throw new BadRequestException('No files uploaded');
    }

    if (productId) {
      const product = await this.prisma.product.findFirst({
        where: { id: productId, deletedAt: null },
      });
      if (!product) throw new NotFoundException('Product not found');
    }

    const results = [];
    let sortOrder =
      productId
        ? await this.prisma.productImage.count({ where: { productId } })
        : 0;

    for (const file of files) {
      const processed = await this.imageProcessor.processProductImage(file);
      const baseName = file.originalname.replace(/\.[^.]+$/, '').slice(0, 40);

      const uploaded = await this.cloudinary.uploadImagePair(
        processed.main,
        processed.thumbnail,
        CLOUDINARY_FOLDERS.products,
        baseName,
      );

      let record = null;
      if (productId) {
        const isFirst = sortOrder === 0;
        record = await this.prisma.productImage.create({
          data: {
            productId,
            imageUrl: uploaded.imageUrl,
            thumbnailUrl: uploaded.thumbnailUrl,
            publicId: uploaded.publicId,
            altText: altText ?? file.originalname,
            sortOrder,
            isFeatured: isFirst,
            width: processed.width,
            height: processed.height,
            format: processed.format,
            bytes: processed.bytes,
          },
        });
        sortOrder++;
      }

      results.push({
        id: record?.id,
        productId: productId ?? null,
        imageUrl: uploaded.imageUrl,
        thumbnailUrl: uploaded.thumbnailUrl,
        publicId: uploaded.publicId,
        altText: altText ?? file.originalname,
        sortOrder: record?.sortOrder ?? null,
        isFeatured: record?.isFeatured ?? false,
      });
    }

    if (productId) {
      await this.syncProductImagesArray(productId);
    }

    return { success: true, images: results };
  }

  async uploadBannerImages(files: Express.Multer.File[]) {
    this.ensureCloudinary();
    if (!files?.length) {
      throw new BadRequestException('No files uploaded');
    }

    const results = [];
    for (const file of files) {
      const processed = await this.imageProcessor.processBannerImage(file);
      const baseName = file.originalname.replace(/\.[^.]+$/, '').slice(0, 40);

      const uploaded = await this.cloudinary.uploadImagePair(
        processed.main,
        processed.thumbnail,
        CLOUDINARY_FOLDERS.banners,
        baseName,
      );

      results.push({
        imageUrl: uploaded.imageUrl,
        thumbnailUrl: uploaded.thumbnailUrl,
        publicId: uploaded.publicId,
        width: processed.width,
        height: processed.height,
      });
    }

    return { success: true, images: results };
  }

  async deleteByPublicId(publicId: string) {
    this.ensureCloudinary();

    const decodedId = decodeURIComponent(publicId);
    const productImage = await this.prisma.productImage.findFirst({
      where: { publicId: decodedId },
    });

    await this.cloudinary.deleteImage(decodedId);

    if (productImage) {
      await this.prisma.productImage.delete({
        where: { id: productImage.id },
      });
      await this.syncProductImagesArray(productImage.productId);
      await this.ensureFeaturedImage(productImage.productId);
    }

    return { success: true, message: 'Image deleted' };
  }

  async deleteProductImage(imageId: string) {
    const image = await this.prisma.productImage.findUnique({
      where: { id: imageId },
    });
    if (!image) throw new NotFoundException('Image not found');

    await this.cloudinary.deleteImage(image.publicId);
    await this.prisma.productImage.delete({ where: { id: imageId } });
    await this.syncProductImagesArray(image.productId);
    await this.ensureFeaturedImage(image.productId);

    return { success: true };
  }

  async reorderProductImages(
    productId: string,
    imageIds: string[],
  ) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, deletedAt: null },
    });
    if (!product) throw new NotFoundException('Product not found');

    await Promise.all(
      imageIds.map((id, index) =>
        this.prisma.productImage.update({
          where: { id, productId },
          data: { sortOrder: index },
        }),
      ),
    );

    await this.syncProductImagesArray(productId);
    return this.getProductImages(productId);
  }

  async setFeaturedImage(productId: string, imageId: string) {
    await this.prisma.productImage.updateMany({
      where: { productId },
      data: { isFeatured: false },
    });
    await this.prisma.productImage.update({
      where: { id: imageId, productId },
      data: { isFeatured: true, sortOrder: 0 },
    });

    const images = await this.prisma.productImage.findMany({
      where: { productId },
      orderBy: [{ isFeatured: 'desc' }, { sortOrder: 'asc' }],
    });

    await Promise.all(
      images.map((img, index) =>
        this.prisma.productImage.update({
          where: { id: img.id },
          data: { sortOrder: index },
        }),
      ),
    );

    await this.syncProductImagesArray(productId);
    return this.getProductImages(productId);
  }

  async getProductImages(productId: string) {
    return this.prisma.productImage.findMany({
      where: { productId },
      orderBy: [{ isFeatured: 'desc' }, { sortOrder: 'asc' }],
    });
  }

  async syncProductImagesArray(productId: string) {
    const images = await this.getProductImages(productId);
    const urls = images.map((i) => i.imageUrl);
    await this.prisma.product.update({
      where: { id: productId },
      data: { images: urls },
    });
  }

  private async ensureFeaturedImage(productId: string) {
    const featured = await this.prisma.productImage.findFirst({
      where: { productId, isFeatured: true },
    });
    if (featured) return;

    const first = await this.prisma.productImage.findFirst({
      where: { productId },
      orderBy: { sortOrder: 'asc' },
    });
    if (first) {
      await this.prisma.productImage.update({
        where: { id: first.id },
        data: { isFeatured: true },
      });
    }
  }
}
