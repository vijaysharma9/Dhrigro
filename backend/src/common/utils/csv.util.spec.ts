import { parseCsv } from './csv.util';

describe('parseCsv', () => {
  it('parses quoted fields and headers', () => {
    const text =
      'name,category,basePrice\n' +
      '"Bananas","Fruits & Vegetables",49\n' +
      'Surf Excel,Detergents,199';

    const rows = parseCsv(text);
    expect(rows).toHaveLength(2);
    expect(rows[0]).toEqual({
      name: 'Bananas',
      category: 'Fruits & Vegetables',
      baseprice: '49',
    });
    expect(rows[1].name).toBe('Surf Excel');
  });
});
