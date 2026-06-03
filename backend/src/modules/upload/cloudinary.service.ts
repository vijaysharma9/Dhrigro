import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';
import { Readable } from 'stream';

export interface CloudinaryUploadResult {
  publicId: string;
  imageUrl: string;
  thumbnailUrl: string;
  width?: number;
  height?: number;
  format?: string;
  bytes?: number;
}

@Injectable()
export class CloudinaryService implements OnModuleInit {
  private readonly logger = new Logger(CloudinaryService.name);
  private configured = false;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const cloudName = this.configService.get<string>('cloudinary.cloudName');
    const apiKey = this.configService.get<string>('cloudinary.apiKey');
    const apiSecret = this.configService.get<string>('cloudinary.apiSecret');

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
        secure: true,
      });
      this.configured = true;
      this.logger.log('Cloudinary configured');
    } else {
      this.logger.warn('Cloudinary not configured — uploads disabled');
    }
  }

  isConfigured(): boolean {
    return this.configured;
  }

  private uploadBuffer(
    buffer: Buffer,
    folder: string,
    filename: string,
  ): Promise<UploadApiResponse> {
    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        {
          folder,
          public_id: `${filename}-${Date.now()}`,
          resource_type: 'image',
          format: 'webp',
        },
        (error, result) => {
          if (error || !result) {
            reject(error ?? new Error('Upload failed'));
          } else {
            resolve(result);
          }
        },
      );
      Readable.from(buffer).pipe(stream);
    });
  }

  async uploadImagePair(
    mainBuffer: Buffer,
    thumbBuffer: Buffer,
    folder: string,
    baseName: string,
  ): Promise<CloudinaryUploadResult> {
    if (!this.configured) {
      throw new Error('Cloudinary is not configured');
    }

    const mainResult = await this.uploadBuffer(mainBuffer, folder, baseName);
    const thumbResult = await this.uploadBuffer(
      thumbBuffer,
      `${folder}/thumbs`,
      `${baseName}-thumb`,
    );

    return {
      publicId: mainResult.public_id,
      imageUrl: mainResult.secure_url,
      thumbnailUrl: thumbResult.secure_url,
      width: mainResult.width,
      height: mainResult.height,
      format: mainResult.format,
      bytes: mainResult.bytes,
    };
  }

  getThumbnailUrl(publicId: string, width = 300, height = 300): string {
    return cloudinary.url(publicId, {
      width,
      height,
      crop: 'fill',
      format: 'webp',
      quality: 'auto',
      secure: true,
    });
  }

  async deleteImage(publicId: string): Promise<void> {
    if (!this.configured) return;
    await cloudinary.uploader.destroy(publicId, { resource_type: 'image' });
  }

  async deleteByPrefix(prefix: string): Promise<void> {
    if (!this.configured) return;
    await cloudinary.api.delete_resources_by_prefix(prefix);
  }
}
