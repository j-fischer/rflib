/**
 * Unified pagination controls with the Rows per page selector (RFLIB 11.5.0). The Log Monitor and
 * User Permission Assignments use the same paginator; the Permissions Explorer always has enough
 * records to show several pages.
 *
 * Produces:
 *   screenshots/Permission_Explorer_Pagination.png  - the page number box and the open Rows per page selector
 *
 * Run: node e2e/tools/capture.mjs recipe e2e/tools/recipes/Permission_Explorer_Pagination.mjs
 */
export const target = { tab: 'Permissions Explorer', settle: 20000 };

export default async function ({ page, root, shoot }) {
    const selector = root.locator('lightning-combobox[data-id="page-size-selector"]');
    await selector.scrollIntoViewIfNeeded();
    await selector.getByRole('combobox').click();
    await page.getByRole('option', { name: '25' }).waitFor({ state: 'visible' });
    await shoot('screenshots/Permission_Explorer_Pagination.png');
}
