import { PrismaClient } from '@prisma/client';
import { syncCategories } from './category-sync';
import { buildCategoryAliasIndex } from '../src/modules/categories/category-master.config';

const prisma = new PrismaClient();

/**
 * Live migration:
 *  1. Syncs the CATEGORY_MASTER config (categories + subcategories + aliases,
 *     remapping legacy categories and retiring strays).
 *  2. Backfills subcategoryId for existing products by matching the product name
 *     against the alias index, so old products gain a subcategory automatically.
 */
async function main() {
  console.log('🗂  Updating category master data…');

  const slugToId = await syncCategories(prisma);
  console.log(`  ✔ Synced ${Object.keys(slugToId).length} categories/subcategories`);

  const aliasIndex = buildCategoryAliasIndex();

  const products = await prisma.product.findMany({
    where: { subcategoryId: null, deletedAt: null },
    select: { id: true, name: true, categoryId: true },
  });

  let backfilled = 0;
  for (const p of products) {
    const haystack = p.name.toLowerCase();
    let match: { categorySlug: string; subcategorySlug?: string } | undefined;

    // Prefer the longest alias that appears in the product name.
    let bestLen = 0;
    for (const [alias, value] of aliasIndex.entries()) {
      if (!value.subcategorySlug) continue;
      if (haystack.includes(alias) && alias.length > bestLen) {
        match = value;
        bestLen = alias.length;
      }
    }

    if (match?.subcategorySlug && slugToId[match.subcategorySlug]) {
      await prisma.product.update({
        where: { id: p.id },
        data: { subcategoryId: slugToId[match.subcategorySlug] },
      });
      backfilled += 1;
    }
  }

  console.log(`  ✔ Backfilled subcategory for ${backfilled} product(s)`);
  console.log('✅ Category migration complete');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
