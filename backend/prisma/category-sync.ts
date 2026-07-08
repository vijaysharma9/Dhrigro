import { PrismaClient } from '@prisma/client';
import {
  CATEGORY_MASTER,
  LEGACY_CATEGORY_REMAP,
} from '../src/modules/categories/category-master.config';

/**
 * Syncs the CATEGORY_MASTER config into the database:
 *  - upserts every top-level category (icon, colour, aliases, featured, order)
 *  - upserts every subcategory as a child (parentId)
 *  - remaps products from retired/legacy categories to their new home
 *  - soft-deactivates any category not present in the config that has no products
 *
 * Returns a slug -> id map for both categories and subcategories.
 */
export async function syncCategories(
  prisma: PrismaClient,
): Promise<Record<string, string>> {
  const slugToId: Record<string, string> = {};

  let order = 1;
  for (const cat of CATEGORY_MASTER) {
    const parent = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {
        name: cat.name,
        description: cat.description ?? null,
        icon: cat.icon,
        color: cat.color,
        sortOrder: order,
        isFeatured: cat.isFeatured ?? false,
        aliases: cat.aliases,
        isActive: true,
        deletedAt: null,
        parentId: null,
      },
      create: {
        name: cat.name,
        slug: cat.slug,
        description: cat.description ?? null,
        icon: cat.icon,
        color: cat.color,
        sortOrder: order,
        isFeatured: cat.isFeatured ?? false,
        aliases: cat.aliases,
        imageUrl: `https://placehold.co/200x200/${cat.color.replace('#', '')}/FFFFFF?text=${encodeURIComponent(
          cat.name,
        )}`,
      },
    });
    slugToId[cat.slug] = parent.id;
    order += 1;

    let subOrder = 1;
    for (const s of cat.subcategories) {
      const child = await prisma.category.upsert({
        where: { slug: s.slug },
        update: {
          name: s.name,
          icon: s.icon ?? cat.icon,
          color: cat.color,
          sortOrder: subOrder,
          aliases: s.aliases,
          parentId: parent.id,
          isActive: true,
          deletedAt: null,
        },
        create: {
          name: s.name,
          slug: s.slug,
          icon: s.icon ?? cat.icon,
          color: cat.color,
          sortOrder: subOrder,
          aliases: s.aliases,
          parentId: parent.id,
        },
      });
      slugToId[s.slug] = child.id;
      subOrder += 1;
    }
  }

  // Backward compatibility: remap products sitting on legacy category slugs.
  for (const [legacySlug, targetSlug] of Object.entries(LEGACY_CATEGORY_REMAP)) {
    const legacy = await prisma.category.findUnique({
      where: { slug: legacySlug },
    });
    const targetId = slugToId[targetSlug];
    if (legacy && targetId && legacy.id !== targetId) {
      await prisma.product.updateMany({
        where: { categoryId: legacy.id },
        data: { categoryId: targetId },
      });
      await prisma.category.update({
        where: { id: legacy.id },
        data: { isActive: false, deletedAt: new Date() },
      });
    }
  }

  // Deactivate stray top-level categories not in the config and with no products.
  const knownSlugs = new Set(Object.keys(slugToId));
  const strays = await prisma.category.findMany({
    where: { parentId: null, deletedAt: null },
    include: { _count: { select: { products: true } } },
  });
  for (const stray of strays) {
    if (!knownSlugs.has(stray.slug) && stray._count.products === 0) {
      await prisma.category.update({
        where: { id: stray.id },
        data: { isActive: false, deletedAt: new Date() },
      });
    }
  }

  return slugToId;
}
