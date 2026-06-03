import { IsArray, IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class UploadProductImagesQueryDto {
  @IsOptional()
  @IsUUID()
  productId?: string;

  @IsOptional()
  @IsString()
  altText?: string;
}

export class ReorderImagesDto {
  @IsNotEmpty()
  @IsUUID()
  productId: string;

  @IsArray()
  @IsUUID('4', { each: true })
  imageIds: string[];
}

export class SetFeaturedImageDto {
  @IsNotEmpty()
  @IsUUID()
  productId: string;

  @IsNotEmpty()
  @IsUUID()
  imageId: string;
}
