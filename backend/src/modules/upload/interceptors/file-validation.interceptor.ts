import {
  BadRequestException,
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import {
  ALLOWED_IMAGE_MIME_TYPES,
  MAX_FILE_SIZE_BYTES,
  MAX_FILES_PER_REQUEST,
} from '../constants/upload.constants';

@Injectable()
export class FileValidationInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest();
    const files: Express.Multer.File[] =
      request.files ??
      (request.file ? [request.file] : []);

    const fileList: Express.Multer.File[] = (
      Array.isArray(files) ? files : Object.values(files).flat()
    ) as Express.Multer.File[];

    if (!fileList.length) {
      throw new BadRequestException('At least one image file is required');
    }

    if (fileList.length > MAX_FILES_PER_REQUEST) {
      throw new BadRequestException(
        `Maximum ${MAX_FILES_PER_REQUEST} files per request`,
      );
    }

    for (const file of fileList) {
      if (file.size > MAX_FILE_SIZE_BYTES) {
        throw new BadRequestException(
          `${file.originalname} exceeds 5MB size limit`,
        );
      }
      if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
        throw new BadRequestException(
          `Invalid type for ${file.originalname}. Allowed: jpg, jpeg, png, webp`,
        );
      }
    }

    return next.handle();
  }
}
