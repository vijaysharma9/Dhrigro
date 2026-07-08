/**
 * CENTRAL CATEGORY MASTER DATA — single source of truth.
 *
 * Every category/subcategory, its aliases (for CSV import + search), icon,
 * colour and display order is defined here. The seed script, import resolver,
 * search and analytics all consume this file. Do NOT hardcode category arrays
 * anywhere else in the codebase.
 *
 * `icon` values are Material icon identifiers so the Flutter apps can map them
 * directly (see apps/daily_rashan category icon resolver).
 */

export interface SubcategoryConfig {
  name: string;
  slug: string;
  aliases: string[];
  icon?: string;
}

export interface CategoryConfig {
  name: string;
  slug: string;
  description?: string;
  icon: string;
  color: string;
  isFeatured?: boolean;
  aliases: string[];
  subcategories: SubcategoryConfig[];
}

const sub = (
  name: string,
  aliases: string[] = [],
  icon?: string,
): SubcategoryConfig => ({
  name,
  slug: slugify(name),
  aliases: dedupe([name, ...aliases]),
  icon,
});

export function slugify(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/&/g, 'and')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function dedupe(values: string[]): string[] {
  return Array.from(new Set(values.map((v) => v.trim().toLowerCase()).filter(Boolean)));
}

export const CATEGORY_MASTER: CategoryConfig[] = [
  {
    name: 'Fruits & Vegetables',
    slug: 'fruits-vegetables',
    icon: 'eco',
    color: '#43A047',
    isFeatured: true,
    aliases: ['produce', 'fruits and vegetables', 'fruit and veg', 'fresh produce'],
    subcategories: [
      sub('Vegetables', ['veg', 'vegetable', 'fresh vegetables'], 'grass'),
      sub('Leafy Vegetables', ['leafy', 'greens', 'spinach', 'saag'], 'spa'),
      sub('Fresh Fruits', ['fruit', 'fruits', 'fresh fruit'], 'nutrition'),
      sub('Herbs', ['herb', 'coriander', 'mint', 'curry leaves'], 'yard'),
    ],
  },
  {
    name: 'Dairy & Refrigerated',
    slug: 'dairy-refrigerated',
    icon: 'egg_alt',
    color: '#42A5F5',
    isFeatured: true,
    aliases: ['dairy', 'refrigerated', 'chilled', 'dairy and refrigerated'],
    subcategories: [
      sub('Milk', ['milk', 'toned milk', 'full cream milk'], 'water_drop'),
      sub('Paneer', ['paneer', 'cottage cheese'], 'crop_square'),
      sub('Cheese', ['cheese', 'mozzarella', 'cheddar'], 'bakery_dining'),
      sub('Butter', ['butter', 'makhan'], 'square'),
      sub('Curd', ['curd', 'dahi', 'yogurt', 'yoghurt'], 'set_meal'),
      sub('Cream', ['cream', 'fresh cream', 'malai'], 'icecream'),
    ],
  },
  {
    name: 'Rice, Flour & Grains',
    slug: 'rice-flour-grains',
    icon: 'rice_bowl',
    color: '#8D6E63',
    isFeatured: true,
    aliases: ['grains', 'staples', 'rice flour and grains', 'cereals'],
    subcategories: [
      sub('Rice', ['rice', 'basmati', 'sona masoori', 'chawal'], 'rice_bowl'),
      sub('Atta', ['atta', 'wheat flour', 'gehu atta'], 'breakfast_dining'),
      sub('Maida', ['maida', 'refined flour', 'all purpose flour'], 'cookie'),
      sub('Flour', ['flour', 'besan', 'gram flour'], 'grain'),
      sub('Rava', ['rava', 'sooji'], 'blur_on'),
      sub('Semolina', ['semolina', 'suji'], 'grain'),
      sub('Poha', ['poha', 'flattened rice', 'aval'], 'dining'),
    ],
  },
  {
    name: 'Pulses & Lentils',
    slug: 'pulses-lentils',
    icon: 'grain',
    color: '#FB8C00',
    aliases: ['pulses', 'lentils', 'dal', 'dals', 'pulses and lentils'],
    subcategories: [
      sub('Toor Dal', ['toor', 'toor dal', 'arhar', 'arhar dal'], 'grain'),
      sub('Moong Dal', ['moong', 'moong dal', 'green gram'], 'grain'),
      sub('Masoor Dal', ['masoor', 'masoor dal', 'red lentil'], 'grain'),
      sub('Chana Dal', ['chana dal', 'bengal gram'], 'grain'),
      sub('Urad Dal', ['urad', 'urad dal', 'black gram'], 'grain'),
      sub('Rajma', ['rajma', 'kidney beans'], 'grain'),
      sub('Kabuli Chana', ['kabuli chana', 'chickpeas', 'chole'], 'grain'),
    ],
  },
  {
    name: 'Spices & Masalas',
    slug: 'spices-masalas',
    icon: 'local_fire_department',
    color: '#E53935',
    isFeatured: true,
    aliases: ['spices', 'masala', 'masalas', 'seasoning', 'spices and masalas'],
    subcategories: [
      sub('Whole Spices', ['whole spices', 'sabut masala', 'khada masala'], 'scatter_plot'),
      sub('Powdered Spices', ['powdered spices', 'ground spices', 'masala powder'], 'blur_on'),
      sub('Blended Masalas', ['blended masala', 'garam masala', 'mixed masala'], 'grain'),
      sub('Salt', ['salt', 'namak'], 'grain'),
      sub('Seasoning', ['seasoning', 'seasonings'], 'shaker'),
    ],
  },
  {
    name: 'Oils & Ghee',
    slug: 'oils-ghee',
    icon: 'water_drop',
    color: '#FDD835',
    aliases: ['oil', 'oils', 'ghee', 'cooking oil', 'oils and ghee'],
    subcategories: [
      sub('Cooking Oil', ['cooking oil', 'refined oil', 'veg oil'], 'water_drop'),
      sub('Mustard Oil', ['mustard oil', 'sarson oil'], 'water_drop'),
      sub('Olive Oil', ['olive oil'], 'water_drop'),
      sub('Sunflower Oil', ['sunflower oil'], 'water_drop'),
      sub('Groundnut Oil', ['groundnut oil', 'peanut oil'], 'water_drop'),
      sub('Ghee', ['ghee', 'desi ghee', 'clarified butter'], 'local_fire_department'),
    ],
  },
  {
    name: 'Sauces & Condiments',
    slug: 'sauces-condiments',
    icon: 'liquor',
    color: '#D81B60',
    aliases: ['sauces', 'condiments', 'sauce', 'sauces and condiments'],
    subcategories: [
      sub('Tomato Ketchup', ['ketchup', 'tomato ketchup', 'tomato sauce'], 'liquor'),
      sub('Soy Sauce', ['soy sauce', 'soya sauce'], 'liquor'),
      sub('Mayonnaise', ['mayonnaise', 'mayo'], 'liquor'),
      sub('Vinegar', ['vinegar', 'sirka'], 'liquor'),
      sub('Chilli Sauce', ['chilli sauce', 'red chilli sauce', 'hot sauce'], 'liquor'),
      sub('Schezwan Sauce', ['schezwan sauce', 'szechuan sauce'], 'liquor'),
    ],
  },
  {
    name: 'Pasta, Noodles & Ready Mix',
    slug: 'pasta-noodles-ready-mix',
    icon: 'ramen_dining',
    color: '#F4511E',
    aliases: ['pasta', 'noodles', 'ready mix', 'instant'],
    subcategories: [
      sub('Pasta', ['pasta', 'penne', 'macaroni', 'spaghetti'], 'ramen_dining'),
      sub('Noodles', ['noodles', 'hakka noodles', 'instant noodles'], 'ramen_dining'),
      sub('Ready Mix', ['ready mix', 'instant mix', 'premix'], 'blender'),
      sub('Momo Wrapper', ['momo wrapper', 'momo sheet', 'dumpling wrapper'], 'wrap_text'),
    ],
  },
  {
    name: 'Bakery & Breads',
    slug: 'bakery-breads',
    icon: 'bakery_dining',
    color: '#C68642',
    aliases: ['bakery', 'breads', 'bread', 'bakery and breads'],
    subcategories: [
      sub('Bread', ['bread', 'loaf', 'sandwich bread'], 'bakery_dining'),
      sub('Burger Bun', ['burger bun', 'bun', 'buns'], 'lunch_dining'),
      sub('Pizza Base', ['pizza base', 'pizza bread'], 'local_pizza'),
      sub('Pav', ['pav', 'ladi pav'], 'bakery_dining'),
      sub('Bread Crumbs', ['bread crumbs', 'breadcrumbs'], 'grain'),
    ],
  },
  {
    name: 'Dry Fruits & Nuts',
    slug: 'dry-fruits-nuts',
    icon: 'nutrition',
    color: '#795548',
    aliases: ['dry fruits', 'nuts', 'dry fruits and nuts'],
    subcategories: [
      sub('Cashew', ['cashew', 'kaju'], 'nutrition'),
      sub('Almond', ['almond', 'badam'], 'nutrition'),
      sub('Pistachio', ['pistachio', 'pista'], 'nutrition'),
      sub('Walnut', ['walnut', 'akhrot'], 'nutrition'),
      sub('Raisins', ['raisins', 'kishmish'], 'nutrition'),
    ],
  },
  {
    name: 'Sugar & Sweeteners',
    slug: 'sugar-sweeteners',
    icon: 'cake',
    color: '#EC407A',
    aliases: ['sugar', 'sweeteners', 'sweetener', 'sugar and sweeteners'],
    subcategories: [
      sub('Sugar', ['sugar', 'cheeni'], 'cake'),
      sub('Brown Sugar', ['brown sugar'], 'cake'),
      sub('Honey', ['honey', 'shahad'], 'water_drop'),
      sub('Jaggery', ['jaggery', 'gud', 'gur'], 'cake'),
    ],
  },
  {
    name: 'Beverages',
    slug: 'beverages',
    icon: 'local_cafe',
    color: '#6D4C41',
    isFeatured: true,
    aliases: ['beverage', 'beverages', 'drinks', 'drink'],
    subcategories: [
      sub('Tea', ['tea', 'chai'], 'emoji_food_beverage'),
      sub('Coffee', ['coffee'], 'local_cafe'),
      sub('Juice', ['juice', 'juices'], 'local_drink'),
      sub('Soft Drinks', ['soft drinks', 'cold drink', 'soda'], 'local_bar'),
      sub('Water', ['water', 'mineral water', 'packaged water'], 'water_drop'),
    ],
  },
  {
    name: 'Frozen Foods',
    slug: 'frozen-foods',
    icon: 'ac_unit',
    color: '#26C6DA',
    aliases: ['frozen', 'frozen foods', 'frozen food'],
    subcategories: [
      sub('Frozen Vegetables', ['frozen vegetables', 'frozen veg'], 'ac_unit'),
      sub('Frozen Corn', ['frozen corn', 'sweet corn'], 'ac_unit'),
      sub('Frozen Peas', ['frozen peas', 'matar'], 'ac_unit'),
      sub('Frozen Snacks', ['frozen snacks', 'nuggets', 'fries'], 'ac_unit'),
    ],
  },
  {
    name: 'Desserts & Sweets',
    slug: 'desserts-sweets',
    icon: 'icecream',
    color: '#AB47BC',
    aliases: ['desserts', 'sweets', 'mithai', 'desserts and sweets'],
    subcategories: [
      sub('Ice Cream', ['ice cream', 'icecream'], 'icecream'),
      sub('Gulab Jamun', ['gulab jamun'], 'cake'),
      sub('Rasgulla', ['rasgulla', 'rosogolla'], 'cake'),
      sub('Sweets', ['sweets', 'mithai', 'dessert'], 'cake'),
    ],
  },
  {
    name: 'Cleaning & Hygiene',
    slug: 'cleaning-hygiene',
    icon: 'cleaning_services',
    color: '#00ACC1',
    aliases: ['cleaning', 'hygiene', 'household', 'cleaning and hygiene'],
    subcategories: [
      sub('Dishwash', ['dishwash', 'dish wash', 'dishwashing'], 'wash'),
      sub('Floor Cleaner', ['floor cleaner', 'phenyl'], 'cleaning_services'),
      sub('Toilet Cleaner', ['toilet cleaner'], 'wc'),
      sub('Garbage Bags', ['garbage bags', 'trash bags', 'dustbin bags'], 'delete'),
      sub('Gloves', ['gloves', 'hand gloves'], 'back_hand'),
      sub('Tissue', ['tissue', 'tissues', 'napkin'], 'dry_cleaning'),
      sub('Hand Wash', ['hand wash', 'handwash', 'soap'], 'sanitizer'),
    ],
  },
  {
    name: 'Packaging Materials',
    slug: 'packaging-materials',
    icon: 'inventory_2',
    color: '#78909C',
    aliases: ['packaging', 'packaging materials', 'packing'],
    subcategories: [
      sub('Plastic Containers', ['plastic containers', 'plastic box'], 'inventory_2'),
      sub('Paper Containers', ['paper containers', 'paper box'], 'inventory_2'),
      sub('Aluminium Foil', ['aluminium foil', 'aluminum foil', 'foil'], 'layers'),
      sub('Butter Paper', ['butter paper', 'parchment paper'], 'description'),
      sub('Cling Film', ['cling film', 'cling wrap', 'plastic wrap'], 'wrap_text'),
      sub('Carry Bags', ['carry bags', 'carry bag', 'shopping bags'], 'shopping_bag'),
    ],
  },
];

/** Legacy category names → new canonical slug (backward compatibility). */
export const LEGACY_CATEGORY_REMAP: Record<string, string> = {
  'dairy-breakfast': 'dairy-refrigerated',
  'snacks-beverages': 'beverages',
  'staples-grains': 'rice-flour-grains',
  household: 'cleaning-hygiene',
  'personal-care': 'cleaning-hygiene',
};

export interface CategoryResolution {
  categoryId: string;
  categorySlug: string;
  subcategoryId?: string;
  subcategorySlug?: string;
}

/**
 * Builds a lookup index for resolving a free-text category/subcategory/alias
 * to concrete category + subcategory slugs. Consumed by import + search.
 */
export function buildCategoryAliasIndex(): Map<
  string,
  { categorySlug: string; subcategorySlug?: string }
> {
  const index = new Map<string, { categorySlug: string; subcategorySlug?: string }>();
  const add = (
    key: string,
    value: { categorySlug: string; subcategorySlug?: string },
  ) => {
    const norm = key.trim().toLowerCase();
    if (norm && !index.has(norm)) index.set(norm, value);
  };

  for (const cat of CATEGORY_MASTER) {
    add(cat.name, { categorySlug: cat.slug });
    add(cat.slug, { categorySlug: cat.slug });
    for (const alias of cat.aliases) add(alias, { categorySlug: cat.slug });

    for (const s of cat.subcategories) {
      const value = { categorySlug: cat.slug, subcategorySlug: s.slug };
      add(s.name, value);
      add(s.slug, value);
      for (const alias of s.aliases) add(alias, value);
    }
  }

  for (const [legacy, slug] of Object.entries(LEGACY_CATEGORY_REMAP)) {
    add(legacy, { categorySlug: slug });
  }

  return index;
}
