import { Module } from '@nestjs/common';
import { UploadService } from './upload.service';
import { UploadController } from './upload.controller';
import { CloudinaryService } from './cloudinary.service';
import { ImageProcessorService } from './utils/image-processor.service';

@Module({
  controllers: [UploadController],
  providers: [UploadService, CloudinaryService, ImageProcessorService],
  exports: [UploadService, CloudinaryService],
})
export class UploadModule {}
