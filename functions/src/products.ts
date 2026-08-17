/**
 * The single source of truth for which store products grant 딸꾹 PRO.
 *
 * Keep in sync with lib/core/services/iap_service.dart — the client uses the
 * same allow-list to decide which transactions are worth sending here, and the
 * server uses it to decide what a verified transaction actually grants.
 */

export type ProductKind = 'lifetime' | 'subscription';

export interface ProProduct {
  readonly kind: ProductKind;
  /** false once a product is retired from the paywall but still honored. */
  readonly purchasable: boolean;
}

export const PRO_PRODUCTS: Readonly<Record<string, ProProduct>> = {
  // Non-consumable, one-time purchase. Never expires.
  lifetime_v1: {kind: 'lifetime', purchasable: true},
  // Auto-renewable annual subscription.
  yearly_v2: {kind: 'subscription', purchasable: true},
  // Retired product id, briefly live in April 2026 before being renamed to
  // yearly_v2. Anyone who bought it keeps their entitlement.
  yearly_v1: {kind: 'subscription', purchasable: false},
};

export function proProduct(productId: string | undefined): ProProduct | null {
  if (!productId) {
    return null;
  }
  return PRO_PRODUCTS[productId] ?? null;
}

export function isProProduct(productId: string | undefined): boolean {
  return proProduct(productId) !== null;
}
