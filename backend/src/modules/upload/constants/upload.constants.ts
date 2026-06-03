export const ALLOWED_IMAGE_MIME_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
];

export const ALLOWED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp'];

export const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5MB

export const MAX_FILES_PER_REQUEST = 10;

export const PRODUCT_IMAGE_MAX_WIDTH = 1200;
export const THUMBNAIL_SIZE = 300;
export const BANNER_IMAGE_MAX_WIDTH = 1600;

export const CLOUDINARY_FOLDERS = {
  products: 'daily-rashan/products',
  banners: 'daily-rashan/banners',
};
