import { Injectable, BadRequestException } from '@nestjs/common';
import sharp from 'sharp';
import {
  ALLOWED_IMAGE_MIME_TYPES,
  MAX_FILE_SIZE_BYTES,
  PRODUCT_IMAGE_MAX_WIDTH,
  THUMBNAIL_SIZE,
  BANNER_IMAGE_MAX_WIDTH,
} from '../constants/upload.constants';

export interface ProcessedImageBuffers {
  main: Buffer;
  thumbnail: Buffer;
  width: number;
  height: number;
  format: string;
  bytes: number;
}

@Injectable()
export class ImageProcessorService {
  validateFile(file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }
    if (file.size > MAX_FILE_SIZE_BYTES) {
      throw new BadRequestException(
        `File ${file.originalname} exceeds 5MB limit`,
      );
    }
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid file type: ${file.mimetype}. Allowed: jpg, jpeg, png, webp`,
      );
    }
  }

  async processProductImage(
    file: Express.Multer.File,
  ): Promise<ProcessedImageBuffers> {
    this.validateFile(file);
    return this.process(file.buffer, PRODUCT_IMAGE_MAX_WIDTH);
  }

  async processBannerImage(
    file: Express.Multer.File,
  ): Promise<ProcessedImageBuffers> {
    this.validateFile(file);
    return this.process(file.buffer, BANNER_IMAGE_MAX_WIDTH);
  }

  private async process(
    buffer: Buffer,
    maxWidth: number,
  ): Promise<ProcessedImageBuffers> {
    const image = sharp(buffer);
    const metadata = await image.metadata();

    const main = await sharp(buffer)
      .rotate()
      .resize(maxWidth, maxWidth, {
        fit: 'inside',
        withoutEnlargement: true,
      })
      .webp({ quality: 85 })
      .toBuffer();

    const thumbnail = await sharp(buffer)
      .rotate()
      .resize(THUMBNAIL_SIZE, THUMBNAIL_SIZE, {
        fit: 'cover',
        position: 'centre',
      })
      .webp({ quality: 80 })
      .toBuffer();

    const mainMeta = await sharp(main).metadata();

    return {
      main,
      thumbnail,
      width: mainMeta.width ?? metadata.width ?? 0,
      height: mainMeta.height ?? metadata.height ?? 0,
      format: 'webp',
      bytes: main.length,
    };
  }
}
