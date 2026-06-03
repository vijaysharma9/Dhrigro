import {
  Body,
  Controller,
  Delete,
  Param,
  Patch,
  Post,
  Query,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { memoryStorage } from 'multer';
import { UploadService } from './upload.service';
import { FileValidationInterceptor } from './interceptors/file-validation.interceptor';
import {
  ReorderImagesDto,
  SetFeaturedImageDto,
  UploadProductImagesQueryDto,
} from './dto/upload.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

const multerOptions = {
  storage: memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 10 },
};

@ApiTags('Uploads')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN)
@Controller('uploads')
export class UploadController {
  constructor(private uploadService: UploadService) {}

  @Post('product-images')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FilesInterceptor('files', 10, multerOptions),
    FileValidationInterceptor,
  )
  uploadProductImages(
    @UploadedFiles() files: Express.Multer.File[],
    @Query() query: UploadProductImagesQueryDto,
  ) {
    return this.uploadService.uploadProductImages(
      files,
      query.productId,
      query.altText,
    );
  }

  @Post('banner-images')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FilesInterceptor('files', 5, multerOptions),
    FileValidationInterceptor,
  )
  uploadBannerImages(@UploadedFiles() files: Express.Multer.File[]) {
    return this.uploadService.uploadBannerImages(files);
  }

  @Delete('product-images/:imageId')
  deleteProductImage(@Param('imageId') imageId: string) {
    return this.uploadService.deleteProductImage(imageId);
  }

  @Delete(':publicId')
  deleteByPublicId(@Param('publicId') publicId: string) {
    return this.uploadService.deleteByPublicId(publicId);
  }

  @Patch('product-images/reorder')
  reorderImages(@Body() dto: ReorderImagesDto) {
    return this.uploadService.reorderProductImages(
      dto.productId,
      dto.imageIds,
    );
  }

  @Patch('product-images/featured')
  setFeatured(@Body() dto: SetFeaturedImageDto) {
    return this.uploadService.setFeaturedImage(dto.productId, dto.imageId);
  }
}
