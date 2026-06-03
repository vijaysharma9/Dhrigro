/**
 * Architecture-ready abstractions for future modules.
 * Implementations are stubs — wire real services when launching each feature.
 */

export interface IWalletService {
  getBalance(userId: string): Promise<number>;
  credit(userId: string, amount: number, reason: string): Promise<void>;
}

export interface ILoyaltyService {
  getPoints(userId: string): Promise<number>;
  earnForOrder(userId: string, orderId: string, amount: number): Promise<void>;
}

export interface IReferralService {
  applyReferralCode(userId: string, code: string): Promise<void>;
  getReferralStats(userId: string): Promise<{ invited: number; earned: number }>;
}

export interface ISubscriptionService {
  listPlans(): Promise<unknown[]>;
  subscribe(userId: string, planId: string): Promise<void>;
}

export interface IRecommendationService {
  getPersonalizedFeed(userId: string): Promise<string[]>;
}

export interface IVendorMarketplaceService {
  listVendors(): Promise<unknown[]>;
}

export interface IDynamicPricingService {
  resolvePrice(productId: string, context: Record<string, unknown>): Promise<number>;
}
