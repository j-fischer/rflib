/**
 * Fields Without FLS in the Permissions Explorer (RFLIB 11.2.0).
 *
 * Produces:
 *   screenshots/Permission_Explorer_Fields_Without_FLS_Menu.png  - the menu open on Hidden/Shown
 *   screenshots/Permission_Explorer_Fields_Without_FLS.png       - the synthesized rows in the table
 *
 * Run: node .claude/skills/rflib-docs/capture.mjs recipe e2e/tools/recipes/Permission_Explorer_Fields_Without_FLS.mjs
 */
export const target = { tab: 'Permissions Explorer', settle: 20000 };

export default async function ({ page, root, shoot, settle }) {
    // Field permission views are the only ones that render the menu.
    await root.getByRole('button', { name: 'Object Permission For Profiles' }).click();
    await page.getByRole('menuitem', { name: 'Field Permissions for Profiles' }).click();
    // Field permissions page through far more records than object permissions.
    await settle(45000);

    const menu = root.getByRole('button', { name: 'Fields Without FLS' });
    await menu.click();
    await page.waitForTimeout(1000);
    await shoot('screenshots/Permission_Explorer_Fields_Without_FLS_Menu.png');

    await page.getByRole('menuitemcheckbox', { name: 'Shown' }).click();
    // Describe calls run per object in the current result set.
    await settle(20000);

    // Page 1 is Account's alphabetical FLS rows, so the synthesized rows the shot is
    // about are thousands of pages away. Search for a system field to bring them up.
    await root.getByPlaceholder('Search field...').fill('CreatedById');
    await root.getByRole('button', { name: 'Search' }).click();
    await settle(5000);
    await shoot('screenshots/Permission_Explorer_Fields_Without_FLS.png');
}
