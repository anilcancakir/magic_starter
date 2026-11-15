import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic/magic.dart';
import 'package:material_ui/material_ui.dart' show MaterialColor;
import 'package:magic_starter/src/configuration/magic_starter_theme.dart';
import 'package:magic_starter/src/ui/theme/magic_starter_tokens.dart';

void main() {
  // -------------------------------------------------------------------------
  // MagicStarterFormTheme
  // -------------------------------------------------------------------------

  group('MagicStarterFormTheme', () {
    group('defaults', () {
      test('inputClassName contains w-full and rounded-lg', () {
        const theme = MagicStarterFormTheme();

        expect(theme.inputClassName, contains('w-full'));
        expect(theme.inputClassName, contains('rounded-lg'));
        expect(theme.inputClassName, contains('px-3 py-3'));
      });

      test('labelClassName contains text-sm and font-medium', () {
        const theme = MagicStarterFormTheme();

        expect(theme.labelClassName, contains('text-sm'));
        expect(theme.labelClassName, contains('font-medium'));
      });

      test('errorClassName contains text-red-600', () {
        const theme = MagicStarterFormTheme();

        expect(theme.errorClassName, contains('text-red-600'));
      });

      test(
        'primaryButtonClassName contains w-full and leaves the shape out',
        () {
          const theme = MagicStarterFormTheme();

          expect(theme.primaryButtonClassName, contains('w-full'));
          expect(theme.primaryButtonClassName, isNot(contains('rounded')));
          expect(theme.primaryButtonClassName, contains('bg-primary'));
        },
      );

      test('linkClassName contains text-primary', () {
        const theme = MagicStarterFormTheme();

        expect(theme.linkClassName, contains('text-primary'));
      });
    });

    group('custom overrides', () {
      test('accepts custom inputClassName', () {
        const theme = MagicStarterFormTheme(inputClassName: 'custom-input');

        expect(theme.inputClassName, equals('custom-input'));
      });

      test('accepts custom labelClassName', () {
        const theme = MagicStarterFormTheme(labelClassName: 'custom-label');

        expect(theme.labelClassName, equals('custom-label'));
      });

      test('accepts custom errorClassName', () {
        const theme = MagicStarterFormTheme(errorClassName: 'custom-error');

        expect(theme.errorClassName, equals('custom-error'));
      });

      test('accepts custom primaryButtonClassName', () {
        const theme = MagicStarterFormTheme(
          primaryButtonClassName: 'custom-btn',
        );

        expect(theme.primaryButtonClassName, equals('custom-btn'));
      });

      test('accepts custom secondaryButtonClassName', () {
        const theme = MagicStarterFormTheme(
          secondaryButtonClassName: 'custom-secondary-btn',
        );

        expect(theme.secondaryButtonClassName, equals('custom-secondary-btn'));
      });

      test('accepts custom linkClassName', () {
        const theme = MagicStarterFormTheme(linkClassName: 'custom-link');

        expect(theme.linkClassName, equals('custom-link'));
      });

      test('accepts custom checkboxLabelClassName', () {
        const theme = MagicStarterFormTheme(
          checkboxLabelClassName: 'custom-checkbox-label',
        );

        expect(theme.checkboxLabelClassName, equals('custom-checkbox-label'));
      });

      test('non-overridden fields keep their defaults', () {
        const theme = MagicStarterFormTheme(inputClassName: 'custom-input');

        expect(theme.labelClassName, contains('text-sm'));
        expect(theme.errorClassName, contains('text-red-600'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterCardTheme
  // -------------------------------------------------------------------------

  group('MagicStarterCardTheme', () {
    group('defaults', () {
      test('surfaceClassName contains bg-white dark:bg-gray-800', () {
        const theme = MagicStarterCardTheme();

        expect(theme.surfaceClassName, contains('bg-white'));
        expect(theme.surfaceClassName, contains('dark:bg-gray-800'));
      });

      test('insetClassName contains bg-gray-50', () {
        const theme = MagicStarterCardTheme();

        expect(theme.insetClassName, contains('bg-gray-50'));
      });

      test('elevatedClassName contains shadow-md', () {
        const theme = MagicStarterCardTheme();

        expect(theme.elevatedClassName, contains('shadow-md'));
      });

      test('titleClassName contains text-lg and font-semibold', () {
        const theme = MagicStarterCardTheme();

        expect(theme.titleClassName, contains('text-lg'));
        expect(theme.titleClassName, contains('font-semibold'));
      });

      test('titleNoPaddingContainerClassName is px-6 pt-6 pb-3', () {
        const theme = MagicStarterCardTheme();

        expect(
          theme.titleNoPaddingContainerClassName,
          equals('px-6 pt-6 pb-3'),
        );
      });

      test('borderRadius is rounded-2xl', () {
        const theme = MagicStarterCardTheme();

        expect(theme.borderRadius, equals('rounded-2xl'));
      });

      test('paddingClassName is p-6', () {
        const theme = MagicStarterCardTheme();

        expect(theme.paddingClassName, equals('p-6'));
      });
    });

    group('custom overrides', () {
      test('accepts custom surfaceClassName', () {
        const theme = MagicStarterCardTheme(surfaceClassName: 'bg-zinc-900');

        expect(theme.surfaceClassName, equals('bg-zinc-900'));
      });

      test('accepts custom borderRadius', () {
        const theme = MagicStarterCardTheme(borderRadius: 'rounded-xl');

        expect(theme.borderRadius, equals('rounded-xl'));
      });

      test('accepts custom paddingClassName', () {
        const theme = MagicStarterCardTheme(paddingClassName: 'p-8');

        expect(theme.paddingClassName, equals('p-8'));
      });

      test('non-overridden fields keep their defaults', () {
        const theme = MagicStarterCardTheme(borderRadius: 'rounded-xl');

        expect(theme.surfaceClassName, contains('bg-white'));
        expect(theme.titleClassName, contains('font-semibold'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterPageHeaderTheme
  // -------------------------------------------------------------------------

  group('MagicStarterPageHeaderTheme', () {
    group('defaults', () {
      test('titleClassName contains text-2xl and font-bold', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.titleClassName, contains('text-2xl'));
        expect(theme.titleClassName, contains('font-bold'));
      });

      test('subtitleClassName contains text-sm', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.subtitleClassName, contains('text-sm'));
      });

      test('titleClassName uses line-clamp-2 instead of truncate', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.titleClassName, contains('line-clamp-2'));
        expect(theme.titleClassName, isNot(contains('truncate')));
      });

      test('subtitleClassName uses line-clamp-2 instead of truncate', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.subtitleClassName, contains('line-clamp-2'));
        expect(theme.subtitleClassName, isNot(contains('truncate')));
      });

      test('containerClassName contains border-b', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.containerClassName, contains('border-b'));
      });

      test('containerInlineClassName contains flex-row items-center', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.containerInlineClassName, contains('flex-row'));
        expect(theme.containerInlineClassName, contains('items-center'));
      });

      test('actionContainerClassName contains flex flex-row', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.actionContainerClassName, contains('flex'));
        expect(theme.actionContainerClassName, contains('flex-row'));
      });
    });

    group('custom overrides', () {
      test('accepts custom titleClassName', () {
        const theme = MagicStarterPageHeaderTheme(
          titleClassName: 'text-3xl font-black text-white',
        );

        expect(theme.titleClassName, equals('text-3xl font-black text-white'));
      });

      test('accepts custom subtitleClassName', () {
        const theme = MagicStarterPageHeaderTheme(
          subtitleClassName: 'text-xs text-zinc-400',
        );

        expect(theme.subtitleClassName, equals('text-xs text-zinc-400'));
      });

      test('accepts custom containerClassName', () {
        const theme = MagicStarterPageHeaderTheme(
          containerClassName: 'custom-container',
        );

        expect(theme.containerClassName, equals('custom-container'));
      });

      test('non-overridden fields keep their defaults', () {
        const theme = MagicStarterPageHeaderTheme(
          titleClassName: 'text-3xl font-black',
        );

        expect(theme.subtitleClassName, contains('text-sm'));
        expect(theme.containerClassName, contains('border-b'));
      });
    });

    group('large title', () {
      test('is off by default, so no consumer changes', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.largeTitle, isFalse);
      });

      test('the compact bar ships as blurred glass with an opaque twin', () {
        const theme = MagicStarterPageHeaderTheme();

        expect(theme.compactBarClassName, contains('/80'));
        expect(theme.compactBarOpaqueClassName, isNot(contains('/')));
        expect(theme.compactBarBlurSigma, greaterThan(0));
      });

      test('fromWind themes the large title and the bar on the tokens', () {
        final MagicStarterPageHeaderTheme theme = MagicStarterTheme.fromWind(
          WindThemeData(aliases: MagicStarterTokens.defaultAliases),
        ).pageHeader;

        expect(theme.largeTitleClassName, contains('text-fg'));
        expect(theme.compactTitleClassName, contains('text-fg'));
        expect(theme.compactBarClassName, contains('bg-surface-container'));
        expect(
          theme.compactBarOpaqueClassName,
          contains('bg-surface-container'),
        );
      });
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterLayoutTheme
  // -------------------------------------------------------------------------

  group('MagicStarterLayoutTheme', () {
    group('defaults', () {
      test('sidebarWidth is 256', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.sidebarWidth, equals(256));
      });

      test('headerHeight is 64', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.headerHeight, equals(64));
      });

      test('sidebarClassName contains bg-white dark:bg-gray-900', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.sidebarClassName, contains('bg-white'));
        expect(theme.sidebarClassName, contains('dark:bg-gray-900'));
      });

      test('headerClassName contains h-16', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.headerClassName, contains('h-16'));
      });

      test('contentBackgroundLightColor is gray', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.contentBackgroundLightColor, equals('gray'));
      });

      test('contentBackgroundLightShade is 50', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.contentBackgroundLightShade, equals(50));
      });

      test('contentBackgroundDarkShade is 950', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.contentBackgroundDarkShade, equals(950));
      });

      test('drawerBackgroundLightColor is white', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.drawerBackgroundLightColor, equals('white'));
      });

      test('drawerBackgroundLightShade is 50', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.drawerBackgroundLightShade, equals(50));
      });

      test('drawerBackgroundDarkColor is gray', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.drawerBackgroundDarkColor, equals('gray'));
      });

      test('drawerBackgroundDarkShade is 900', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.drawerBackgroundDarkShade, equals(900));
      });

      test('bottomNavClassName is empty string', () {
        const theme = MagicStarterLayoutTheme();

        expect(theme.bottomNavClassName, equals(''));
      });
    });

    group('custom overrides', () {
      test('accepts custom sidebarWidth', () {
        const theme = MagicStarterLayoutTheme(sidebarWidth: 280);

        expect(theme.sidebarWidth, equals(280));
      });

      test('accepts custom headerHeight', () {
        const theme = MagicStarterLayoutTheme(headerHeight: 80);

        expect(theme.headerHeight, equals(80));
      });

      test('accepts custom sidebarClassName', () {
        const theme = MagicStarterLayoutTheme(
          sidebarClassName: 'bg-zinc-900 border-r border-zinc-700',
        );

        expect(
          theme.sidebarClassName,
          equals('bg-zinc-900 border-r border-zinc-700'),
        );
      });

      test('accepts custom contentBackgroundLightColor', () {
        const theme = MagicStarterLayoutTheme(
          contentBackgroundLightColor: 'slate',
        );

        expect(theme.contentBackgroundLightColor, equals('slate'));
      });

      test('accepts custom bottomNavClassName', () {
        const theme = MagicStarterLayoutTheme(
          bottomNavClassName: 'bg-zinc-900 border-t border-zinc-700',
        );

        expect(
          theme.bottomNavClassName,
          equals('bg-zinc-900 border-t border-zinc-700'),
        );
      });

      test('non-overridden fields keep their defaults', () {
        const theme = MagicStarterLayoutTheme(sidebarWidth: 300);

        expect(theme.headerHeight, equals(64));
        expect(theme.contentBackgroundLightColor, equals('gray'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterAuthTheme
  // -------------------------------------------------------------------------

  group('MagicStarterAuthTheme', () {
    group('defaults', () {
      test('cardClassName contains rounded-2xl bg-white dark:bg-gray-800', () {
        const theme = MagicStarterAuthTheme();

        expect(theme.cardClassName, contains('rounded-2xl'));
        expect(theme.cardClassName, contains('bg-white'));
        expect(theme.cardClassName, contains('dark:bg-gray-800'));
      });

      test('titleClassName contains text-2xl and font-bold', () {
        const theme = MagicStarterAuthTheme();

        expect(theme.titleClassName, contains('text-2xl'));
        expect(theme.titleClassName, contains('font-bold'));
      });

      test('subtitleClassName contains text-sm', () {
        const theme = MagicStarterAuthTheme();

        expect(theme.subtitleClassName, contains('text-sm'));
      });

      test('errorBannerClassName contains bg-red-50 and text-red-700', () {
        const theme = MagicStarterAuthTheme();

        expect(theme.errorBannerClassName, contains('bg-red-50'));
        expect(theme.errorBannerClassName, contains('text-red-700'));
      });

      test('socialDividerClassName contains flex flex-row', () {
        const theme = MagicStarterAuthTheme();

        expect(theme.socialDividerClassName, contains('flex'));
        expect(theme.socialDividerClassName, contains('flex-row'));
      });

      test('registrationLinkTextClassName contains text-primary', () {
        const theme = MagicStarterAuthTheme();

        expect(theme.registrationLinkTextClassName, contains('text-primary'));
      });
    });

    group('custom overrides', () {
      test('accepts custom cardClassName', () {
        const theme = MagicStarterAuthTheme(
          cardClassName: 'rounded-3xl bg-zinc-900 border border-zinc-700',
        );

        expect(
          theme.cardClassName,
          equals('rounded-3xl bg-zinc-900 border border-zinc-700'),
        );
      });

      test('accepts custom titleClassName', () {
        const theme = MagicStarterAuthTheme(
          titleClassName: 'text-3xl font-black text-white text-center',
        );

        expect(
          theme.titleClassName,
          equals('text-3xl font-black text-white text-center'),
        );
      });

      test('accepts custom errorBannerClassName', () {
        const theme = MagicStarterAuthTheme(
          errorBannerClassName: 'custom-error-banner',
        );

        expect(theme.errorBannerClassName, equals('custom-error-banner'));
      });

      test('accepts custom guestButtonClassName', () {
        const theme = MagicStarterAuthTheme(
          guestButtonClassName: 'custom-guest-btn',
        );

        expect(theme.guestButtonClassName, equals('custom-guest-btn'));
      });

      test('non-overridden fields keep their defaults', () {
        const theme = MagicStarterAuthTheme(cardClassName: 'custom-card');

        expect(theme.titleClassName, contains('font-bold'));
        expect(theme.subtitleClassName, contains('text-sm'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterDropdownTheme
  // -------------------------------------------------------------------------

  group('MagicStarterDropdownTheme', () {
    group('defaults', () {
      test('panel keeps the white and gray-800 fill with a gray edge', () {
        const theme = MagicStarterDropdownTheme();

        expect(
          theme.panelClassName,
          'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700',
        );
      });

      test('divider is a border colour with no width or side', () {
        const theme = MagicStarterDropdownTheme();

        expect(theme.dividerClassName, 'border-gray-100 dark:border-gray-700');
      });

      test('item fills a hovered row', () {
        const theme = MagicStarterDropdownTheme();

        expect(
          theme.itemClassName,
          'hover:bg-gray-50 dark:hover:bg-gray-700/50',
        );
      });

      test('tile is a filled square that steps darker on hover', () {
        const theme = MagicStarterDropdownTheme();

        expect(theme.tileClassName, contains('bg-gray-100 dark:bg-gray-700'));
        expect(
          theme.tileClassName,
          contains('hover:bg-gray-200 dark:hover:bg-gray-600'),
        );
      });

      test('text and muted text carry their own dark pair', () {
        const theme = MagicStarterDropdownTheme();

        expect(theme.textClassName, 'text-gray-900 dark:text-white');
        expect(theme.mutedTextClassName, 'text-gray-500 dark:text-gray-400');
      });

      test('danger fields apply under the danger state only', () {
        const theme = MagicStarterDropdownTheme();

        for (final className in [
          theme.dangerTextClassName,
          theme.dangerTileClassName,
        ]) {
          for (final token in className.split(RegExp(r'\s+'))) {
            expect(
              token.contains('danger:'),
              isTrue,
              reason:
                  '"$token" would colour every row, not only the danger one',
            );
          }
        }
      });
    });

    group('custom overrides', () {
      test('accepts a custom panelClassName', () {
        const theme = MagicStarterDropdownTheme(panelClassName: 'custom-panel');

        expect(theme.panelClassName, equals('custom-panel'));
        expect(theme.itemClassName, contains('hover:'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterButtonTheme
  // -------------------------------------------------------------------------

  group('MagicStarterButtonTheme', () {
    group('defaults', () {
      test('shape is the large radius MSButton always had', () {
        const theme = MagicStarterButtonTheme();

        expect(theme.shapeClassName, 'rounded-lg');
      });

      test('sizes keep the padding and type of the previous recipe', () {
        const theme = MagicStarterButtonTheme();

        expect(theme.smClassName, 'px-3 py-1.5 text-sm');
        expect(theme.mdClassName, 'px-4 py-2 text-sm');
        expect(theme.lgClassName, 'px-5 py-3 text-base');
      });

      test('secondary keeps its one pixel border', () {
        const theme = MagicStarterButtonTheme();

        expect(theme.secondaryBorderClassName, 'border border-color-border');
      });
    });

    group('custom overrides', () {
      test('accepts a custom shapeClassName and keeps the other fields', () {
        const theme = MagicStarterButtonTheme(shapeClassName: 'rounded-full');

        expect(theme.shapeClassName, 'rounded-full');
        expect(theme.mdClassName, 'px-4 py-2 text-sm');
      });
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterFieldTheme
  // -------------------------------------------------------------------------

  group('MagicStarterFieldTheme', () {
    group('defaults', () {
      test('the input keeps the padding and type of the previous recipe', () {
        const theme = MagicStarterFieldTheme();

        expect(theme.inputSizeClassName, 'py-3 lg:py-2.5 text-sm leading-5');
      });

      test('the select and combobox triggers keep their 44 px floor', () {
        const theme = MagicStarterFieldTheme();

        expect(theme.selectSizeClassName, 'py-[9px] min-h-11 lg:min-h-0');
      });

      test('the segmented items keep the padding and type of both sizes', () {
        const theme = MagicStarterFieldTheme();

        expect(theme.segmentedSmClassName, 'px-2 py-1 text-sm');
        expect(theme.segmentedMdClassName, 'px-3 py-1.5 text-sm');
      });

      test('the segmented root keeps its one step of padding', () {
        const theme = MagicStarterFieldTheme();

        expect(theme.segmentedPaddingClassName, 'p-1');
      });
    });

    group('custom overrides', () {
      test(
        'accepts a custom inputSizeClassName and keeps the other fields',
        () {
          const theme = MagicStarterFieldTheme(
            inputSizeClassName: 'py-[11px] text-[17px] leading-[22px]',
          );

          expect(
            theme.inputSizeClassName,
            'py-[11px] text-[17px] leading-[22px]',
          );
          expect(theme.selectSizeClassName, 'py-[9px] min-h-11 lg:min-h-0');
          expect(theme.segmentedMdClassName, 'px-3 py-1.5 text-sm');
        },
      );
    });
  });

  // -------------------------------------------------------------------------
  // MagicStarterTheme (unified wrapper)
  // -------------------------------------------------------------------------

  group('MagicStarterTheme', () {
    group('default constructor', () {
      test('uses default sub-themes when no arguments provided', () {
        const theme = MagicStarterTheme();

        expect(theme.form, isA<MagicStarterFormTheme>());
        expect(theme.card, isA<MagicStarterCardTheme>());
        expect(theme.pageHeader, isA<MagicStarterPageHeaderTheme>());
        expect(theme.layout, isA<MagicStarterLayoutTheme>());
        expect(theme.auth, isA<MagicStarterAuthTheme>());
        expect(theme.navigation, isA<MagicStarterNavigationTheme>());
        expect(theme.modal, isA<MagicStarterModalTheme>());
        expect(theme.dropdown, isA<MagicStarterDropdownTheme>());
        expect(theme.button, isA<MagicStarterButtonTheme>());
        expect(theme.field, isA<MagicStarterFieldTheme>());
      });

      test('default form sub-theme has correct defaults', () {
        const theme = MagicStarterTheme();

        expect(theme.form.inputClassName, contains('w-full'));
        expect(theme.form.primaryButtonClassName, contains('bg-primary'));
      });

      test('default card sub-theme has correct defaults', () {
        const theme = MagicStarterTheme();

        expect(theme.card.surfaceClassName, contains('bg-white'));
        expect(theme.card.borderRadius, equals('rounded-2xl'));
      });

      test('default layout sub-theme has correct numeric defaults', () {
        const theme = MagicStarterTheme();

        expect(theme.layout.sidebarWidth, equals(256));
        expect(theme.layout.headerHeight, equals(64));
      });

      test('default auth sub-theme has correct defaults', () {
        const theme = MagicStarterTheme();

        expect(theme.auth.cardClassName, contains('rounded-2xl'));
      });
    });

    group('custom sub-themes', () {
      test('stores custom form sub-theme', () {
        const customForm = MagicStarterFormTheme(
          inputClassName: 'custom-input',
        );
        const theme = MagicStarterTheme(form: customForm);

        expect(theme.form.inputClassName, equals('custom-input'));
      });

      test('stores custom card sub-theme', () {
        const customCard = MagicStarterCardTheme(borderRadius: 'rounded-xl');
        const theme = MagicStarterTheme(card: customCard);

        expect(theme.card.borderRadius, equals('rounded-xl'));
      });

      test('stores custom layout sub-theme', () {
        const customLayout = MagicStarterLayoutTheme(sidebarWidth: 300);
        const theme = MagicStarterTheme(layout: customLayout);

        expect(theme.layout.sidebarWidth, equals(300));
      });

      test('stores custom auth sub-theme', () {
        const customAuth = MagicStarterAuthTheme(cardClassName: 'custom-card');
        const theme = MagicStarterTheme(auth: customAuth);

        expect(theme.auth.cardClassName, equals('custom-card'));
      });

      test('stores custom dropdown sub-theme', () {
        const customDropdown = MagicStarterDropdownTheme(
          panelClassName: 'custom-panel',
        );
        const theme = MagicStarterTheme(dropdown: customDropdown);

        expect(theme.dropdown.panelClassName, equals('custom-panel'));
      });

      test('stores custom button sub-theme', () {
        const customButton = MagicStarterButtonTheme(
          shapeClassName: 'rounded-full',
        );
        const theme = MagicStarterTheme(button: customButton);

        expect(theme.button.shapeClassName, equals('rounded-full'));
      });

      test('stores custom field sub-theme', () {
        const customField = MagicStarterFieldTheme(
          inputSizeClassName: 'py-[11px] text-[17px] leading-[22px]',
        );
        const theme = MagicStarterTheme(field: customField);

        expect(
          theme.field.inputSizeClassName,
          equals('py-[11px] text-[17px] leading-[22px]'),
        );
      });

      test('other sub-themes remain at defaults when one is customized', () {
        const theme = MagicStarterTheme(
          form: MagicStarterFormTheme(inputClassName: 'custom-input'),
        );

        expect(theme.card.borderRadius, equals('rounded-2xl'));
        expect(theme.layout.sidebarWidth, equals(256));
        expect(theme.auth.cardClassName, contains('rounded-2xl'));
      });
    });

    group('copyWith', () {
      test('overrides one sub-theme while keeping others at defaults', () {
        const original = MagicStarterTheme();
        final updated = original.copyWith(
          form: const MagicStarterFormTheme(inputClassName: 'custom-input'),
        );

        expect(updated.form.inputClassName, equals('custom-input'));
        expect(updated.card.borderRadius, equals('rounded-2xl'));
        expect(updated.layout.sidebarWidth, equals(256));
        expect(updated.auth.cardClassName, contains('rounded-2xl'));
      });

      test('overrides layout sub-theme while keeping others unchanged', () {
        const original = MagicStarterTheme();
        final updated = original.copyWith(
          layout: const MagicStarterLayoutTheme(sidebarWidth: 320),
        );

        expect(updated.layout.sidebarWidth, equals(320));
        expect(updated.form.inputClassName, contains('w-full'));
        expect(updated.card.borderRadius, equals('rounded-2xl'));
      });

      test('overrides auth sub-theme while keeping others unchanged', () {
        const original = MagicStarterTheme();
        final updated = original.copyWith(
          auth: const MagicStarterAuthTheme(cardClassName: 'custom-card'),
        );

        expect(updated.auth.cardClassName, equals('custom-card'));
        expect(updated.form.inputClassName, contains('w-full'));
        expect(updated.layout.headerHeight, equals(64));
      });

      test('overrides dropdown sub-theme while keeping others unchanged', () {
        const original = MagicStarterTheme();
        final updated = original.copyWith(
          dropdown: const MagicStarterDropdownTheme(
            panelClassName: 'custom-panel',
          ),
        );

        expect(updated.dropdown.panelClassName, equals('custom-panel'));
        expect(updated.form.inputClassName, contains('w-full'));
        expect(updated.layout.headerHeight, equals(64));
      });

      test('copyWith with no arguments keeps the dropdown sub-theme', () {
        final updated = const MagicStarterTheme(
          dropdown: MagicStarterDropdownTheme(panelClassName: 'custom-panel'),
        ).copyWith();

        expect(updated.dropdown.panelClassName, equals('custom-panel'));
      });

      test('overrides button sub-theme while keeping others unchanged', () {
        const original = MagicStarterTheme();
        final updated = original.copyWith(
          button: const MagicStarterButtonTheme(shapeClassName: 'rounded-full'),
        );

        expect(updated.button.shapeClassName, equals('rounded-full'));
        expect(updated.dropdown.textClassName, contains('text-gray-900'));
        expect(updated.layout.headerHeight, equals(64));
      });

      test('overrides field sub-theme while keeping others unchanged', () {
        const original = MagicStarterTheme();
        final updated = original.copyWith(
          field: const MagicStarterFieldTheme(
            selectSizeClassName: 'py-2.5 text-[17px] leading-[22px]',
          ),
        );

        expect(
          updated.field.selectSizeClassName,
          equals('py-2.5 text-[17px] leading-[22px]'),
        );
        expect(updated.button.shapeClassName, equals('rounded-lg'));
        expect(updated.layout.headerHeight, equals(64));
      });

      test('copyWith with no arguments keeps the field sub-theme', () {
        final updated = const MagicStarterTheme(
          field: MagicStarterFieldTheme(segmentedPaddingClassName: 'p-0'),
        ).copyWith();

        expect(updated.field.segmentedPaddingClassName, equals('p-0'));
      });

      test('copyWith with no arguments keeps the button sub-theme', () {
        final updated = const MagicStarterTheme(
          button: MagicStarterButtonTheme(shapeClassName: 'rounded-full'),
        ).copyWith();

        expect(updated.button.shapeClassName, equals('rounded-full'));
      });

      test('overrides multiple sub-themes simultaneously', () {
        const original = MagicStarterTheme();
        final updated = original.copyWith(
          form: const MagicStarterFormTheme(inputClassName: 'custom-input'),
          card: const MagicStarterCardTheme(borderRadius: 'rounded-xl'),
          layout: const MagicStarterLayoutTheme(sidebarWidth: 300),
        );

        expect(updated.form.inputClassName, equals('custom-input'));
        expect(updated.card.borderRadius, equals('rounded-xl'));
        expect(updated.layout.sidebarWidth, equals(300));
        expect(updated.auth.cardClassName, contains('rounded-2xl'));
      });

      test('copyWith with no arguments returns equivalent theme', () {
        const original = MagicStarterTheme();
        final copy = original.copyWith();

        expect(copy.form.inputClassName, equals(original.form.inputClassName));
        expect(copy.card.borderRadius, equals(original.card.borderRadius));
        expect(copy.layout.sidebarWidth, equals(original.layout.sidebarWidth));
        expect(copy.layout.headerHeight, equals(original.layout.headerHeight));
        expect(copy.auth.cardClassName, equals(original.auth.cardClassName));
        expect(
          copy.pageHeader.titleClassName,
          equals(original.pageHeader.titleClassName),
        );
      });

      test('copyWith preserves custom sub-themes not being overridden', () {
        final base = const MagicStarterTheme().copyWith(
          form: const MagicStarterFormTheme(inputClassName: 'custom-input'),
        );
        final updated = base.copyWith(
          card: const MagicStarterCardTheme(borderRadius: 'rounded-xl'),
        );

        expect(updated.form.inputClassName, equals('custom-input'));
        expect(updated.card.borderRadius, equals('rounded-xl'));
      });
    });
  });

  // -------------------------------------------------------------------------
  // copyWith on the form and modal themes
  // -------------------------------------------------------------------------

  // `useFormTheme` and `useModalTheme` assign the WHOLE struct, so changing one
  // string used to mean copying every other field by hand, and a field added
  // later went back to its default without a sound. `copyWith` is the supported
  // way, and these tests are what keeps it complete: each theme is built with
  // EVERY field distinct, so a field `copyWith` forgets comes back as its
  // default and differs from the original.
  group('copyWith on the whole-struct sub-themes', () {
    /// The parameters the constructor of [className] declares, read from the
    /// source, so a field added to the class cannot be left out of the table
    /// below without a test failing.
    Set<String> constructorFields(String className) {
      final source = File('lib/src/configuration/magic_starter_theme.dart')
          .readAsStringSync();
      final start = source.indexOf('  const $className({');
      final end = source.indexOf('\n  });', start);

      expect(start, isNonNegative, reason: 'no const $className constructor');

      return RegExp(r'this\.(\w+)')
          .allMatches(source.substring(start, end))
          .map((m) => m.group(1)!)
          .toSet();
    }

    /// A field of a theme: how to read it, and how to set it through
    /// `copyWith` to a value no distinct theme below uses.
    _Field<T> field<T>(
      String name,
      Object? Function(T) read,
      T Function(T) change,
    ) => _Field<T>(name, read, change);

    final formFields = [
      field<MagicStarterFormTheme>(
        'inputClassName',
        (t) => t.inputClassName,
        (t) => t.copyWith(inputClassName: 'changed'),
      ),
      field<MagicStarterFormTheme>(
        'labelClassName',
        (t) => t.labelClassName,
        (t) => t.copyWith(labelClassName: 'changed'),
      ),
      field<MagicStarterFormTheme>(
        'errorClassName',
        (t) => t.errorClassName,
        (t) => t.copyWith(errorClassName: 'changed'),
      ),
      field<MagicStarterFormTheme>(
        'placeholderClassName',
        (t) => t.placeholderClassName,
        (t) => t.copyWith(placeholderClassName: 'changed'),
      ),
      field<MagicStarterFormTheme>(
        'primaryButtonClassName',
        (t) => t.primaryButtonClassName,
        (t) => t.copyWith(primaryButtonClassName: 'changed'),
      ),
      field<MagicStarterFormTheme>(
        'secondaryButtonClassName',
        (t) => t.secondaryButtonClassName,
        (t) => t.copyWith(secondaryButtonClassName: 'changed'),
      ),
      field<MagicStarterFormTheme>(
        'linkClassName',
        (t) => t.linkClassName,
        (t) => t.copyWith(linkClassName: 'changed'),
      ),
      field<MagicStarterFormTheme>(
        'checkboxLabelClassName',
        (t) => t.checkboxLabelClassName,
        (t) => t.copyWith(checkboxLabelClassName: 'changed'),
      ),
    ];

    const distinctForm = MagicStarterFormTheme(
      inputClassName: 'form-input',
      labelClassName: 'form-label',
      errorClassName: 'form-error',
      placeholderClassName: 'form-placeholder',
      primaryButtonClassName: 'form-primary',
      secondaryButtonClassName: 'form-secondary',
      linkClassName: 'form-link',
      checkboxLabelClassName: 'form-checkbox-label',
    );

    final modalFields = [
      field<MagicStarterModalTheme>(
        'containerClassName',
        (t) => t.containerClassName,
        (t) => t.copyWith(containerClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'headerClassName',
        (t) => t.headerClassName,
        (t) => t.copyWith(headerClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'bodyClassName',
        (t) => t.bodyClassName,
        (t) => t.copyWith(bodyClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'headlessBodyClassName',
        (t) => t.headlessBodyClassName,
        (t) => t.copyWith(headlessBodyClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'footerClassName',
        (t) => t.footerClassName,
        (t) => t.copyWith(footerClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'titleClassName',
        (t) => t.titleClassName,
        (t) => t.copyWith(titleClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'descriptionClassName',
        (t) => t.descriptionClassName,
        (t) => t.copyWith(descriptionClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'primaryButtonClassName',
        (t) => t.primaryButtonClassName,
        (t) => t.copyWith(primaryButtonClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'secondaryButtonClassName',
        (t) => t.secondaryButtonClassName,
        (t) => t.copyWith(secondaryButtonClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'dangerButtonClassName',
        (t) => t.dangerButtonClassName,
        (t) => t.copyWith(dangerButtonClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'warningButtonClassName',
        (t) => t.warningButtonClassName,
        (t) => t.copyWith(warningButtonClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'errorClassName',
        (t) => t.errorClassName,
        (t) => t.copyWith(errorClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'inputClassName',
        (t) => t.inputClassName,
        (t) => t.copyWith(inputClassName: 'changed'),
      ),
      field<MagicStarterModalTheme>(
        'maxWidth',
        (t) => t.maxWidth,
        (t) => t.copyWith(maxWidth: 999.0),
      ),
      field<MagicStarterModalTheme>(
        'presentation',
        (t) => t.presentation,
        (t) => t.copyWith(presentation: MagicStarterModalPresentation.dialog),
      ),
      field<MagicStarterModalTheme>(
        'dialogBreakpoint',
        (t) => t.dialogBreakpoint,
        (t) => t.copyWith(dialogBreakpoint: 'xl'),
      ),
    ];

    const distinctModal = MagicStarterModalTheme(
      containerClassName: 'modal-container',
      headerClassName: 'modal-header',
      bodyClassName: 'modal-body',
      headlessBodyClassName: 'modal-headless',
      footerClassName: 'modal-footer',
      titleClassName: 'modal-title',
      descriptionClassName: 'modal-description',
      primaryButtonClassName: 'modal-primary',
      secondaryButtonClassName: 'modal-secondary',
      dangerButtonClassName: 'modal-danger',
      warningButtonClassName: 'modal-warning',
      errorClassName: 'modal-error',
      inputClassName: 'modal-input',
      maxWidth: 321.0,
      presentation: MagicStarterModalPresentation.sheet,
      dialogBreakpoint: 'md',
    );

    /// The same checks for both themes: [original] has every field distinct.
    void expectCopyWithComplete<T>({
      required String className,
      required List<_Field<T>> fields,
      required T original,
      required T defaults,
      required T Function(T) copy,
    }) {
      final names = fields.map((f) => f.name).toSet();

      test('the field table lists every parameter of the constructor', () {
        expect(
          constructorFields(className),
          names,
          reason:
              'a field was added to $className: add it to this table, and to '
              'copyWith, which the checks below then hold to account',
        );
        expect(fields, hasLength(names.length));
      });

      // A boolean has two values, so a theme with three flags cannot hold
      // them apart; each flag is still held against its default below.
      test('the theme under test has every non-boolean field distinct', () {
        final values = fields
            .map((f) => f.read(original))
            .where((value) => value is! bool)
            .toList();

        expect(values.toSet(), hasLength(values.length));
      });

      test('the theme under test differs from the defaults in every field', () {
        for (final f in fields) {
          expect(f.read(original), isNot(f.read(defaults)), reason: f.name);
        }
      });

      test('copyWith with no argument keeps every field', () {
        final copied = copy(original);

        for (final f in fields) {
          expect(f.read(copied), f.read(original), reason: f.name);
        }
      });

      test('copyWith with no argument keeps every default', () {
        final copied = copy(defaults);

        for (final f in fields) {
          expect(f.read(copied), f.read(defaults), reason: f.name);
        }
      });

      for (final changed in fields) {
        test('copyWith of ${changed.name} changes it and nothing else', () {
          final copied = changed.change(original);

          for (final f in fields) {
            if (f.name == changed.name) {
              expect(f.read(copied), isNot(f.read(original)), reason: f.name);
              expect(
                f.read(copied),
                isIn([
                  'changed',
                  999.0,
                  MagicStarterModalPresentation.dialog,
                  'xl',
                  false,
                  _changedBuilder,
                ]),
                reason: f.name,
              );
            } else {
              expect(f.read(copied), f.read(original), reason: f.name);
            }
          }
        });
      }
    }

    group('MagicStarterFormTheme', () {
      expectCopyWithComplete<MagicStarterFormTheme>(
        className: 'MagicStarterFormTheme',
        fields: formFields,
        original: distinctForm,
        defaults: const MagicStarterFormTheme(),
        copy: (t) => t.copyWith(),
      );

      test(
        'is not the same instance, so a setter never aliases the old one',
        () {
          expect(identical(distinctForm.copyWith(), distinctForm), isFalse);
        },
      );
    });

    group('MagicStarterModalTheme', () {
      expectCopyWithComplete<MagicStarterModalTheme>(
        className: 'MagicStarterModalTheme',
        fields: modalFields,
        original: distinctModal,
        defaults: const MagicStarterModalTheme(),
        copy: (t) => t.copyWith(),
      );

      test('presents as a dialog by default and from fromWind', () {
        expect(
          const MagicStarterModalTheme().presentation,
          MagicStarterModalPresentation.dialog,
        );
        expect(
          MagicStarterTheme.fromWind(WindThemeData()).modal.presentation,
          MagicStarterModalPresentation.dialog,
        );
      });

      test('swaps to a dialog from lg when the presentation is adaptive', () {
        expect(const MagicStarterModalTheme().dialogBreakpoint, 'lg');
        expect(
          MagicStarterTheme.fromWind(WindThemeData()).modal.dialogBreakpoint,
          'lg',
        );
      });

      test('keeps the width of a theme that sets one', () {
        expect(
          distinctModal.copyWith(inputClassName: 'changed').maxWidth,
          321.0,
        );
      });
    });

    // The other eight sub-themes take the same table. Their setters assign
    // the whole struct too, so a one-field override is
    // `MagicStarter.<x>Theme.copyWith(...)` there as well.

    group('MagicStarterNavigationTheme', () {
      expectCopyWithComplete<MagicStarterNavigationTheme>(
        className: 'MagicStarterNavigationTheme',
        fields: [
          field(
            'activeItemClassName',
            (t) => t.activeItemClassName,
            (t) => t.copyWith(activeItemClassName: 'changed'),
          ),
          field(
            'hoverItemClassName',
            (t) => t.hoverItemClassName,
            (t) => t.copyWith(hoverItemClassName: 'changed'),
          ),
          field(
            'brandClassName',
            (t) => t.brandClassName,
            (t) => t.copyWith(brandClassName: 'changed'),
          ),
          field(
            'brandBuilder',
            (t) => t.brandBuilder,
            (t) => t.copyWith(brandBuilder: _changedBuilder),
          ),
          field(
            'compactBrandBuilder',
            (t) => t.compactBrandBuilder,
            (t) => t.copyWith(compactBrandBuilder: _changedBuilder),
          ),
          field(
            'bottomNavActiveClassName',
            (t) => t.bottomNavActiveClassName,
            (t) => t.copyWith(bottomNavActiveClassName: 'changed'),
          ),
          field(
            'avatarClassName',
            (t) => t.avatarClassName,
            (t) => t.copyWith(avatarClassName: 'changed'),
          ),
          field(
            'avatarTextClassName',
            (t) => t.avatarTextClassName,
            (t) => t.copyWith(avatarTextClassName: 'changed'),
          ),
          field(
            'dropdownAvatarClassName',
            (t) => t.dropdownAvatarClassName,
            (t) => t.copyWith(dropdownAvatarClassName: 'changed'),
          ),
          field(
            'dropdownAvatarTextClassName',
            (t) => t.dropdownAvatarTextClassName,
            (t) => t.copyWith(dropdownAvatarTextClassName: 'changed'),
          ),
          field(
            'focusItemClassName',
            (t) => t.focusItemClassName,
            (t) => t.copyWith(focusItemClassName: 'changed'),
          ),
          field(
            'badgeClassName',
            (t) => t.badgeClassName,
            (t) => t.copyWith(badgeClassName: 'changed'),
          ),
        ],
        original: const MagicStarterNavigationTheme(
          activeItemClassName: 'nav-active',
          hoverItemClassName: 'nav-hover',
          brandClassName: 'nav-brand',
          brandBuilder: _brandBuilder,
          compactBrandBuilder: _compactBrandBuilder,
          bottomNavActiveClassName: 'nav-bottom-active',
          avatarClassName: 'nav-avatar',
          avatarTextClassName: 'nav-avatar-text',
          dropdownAvatarClassName: 'nav-dropdown-avatar',
          dropdownAvatarTextClassName: 'nav-dropdown-avatar-text',
          focusItemClassName: 'nav-focus',
          badgeClassName: 'nav-badge',
        ),
        defaults: const MagicStarterNavigationTheme(),
        copy: (t) => t.copyWith(),
      );
    });

    group('MagicStarterCardTheme', () {
      expectCopyWithComplete<MagicStarterCardTheme>(
        className: 'MagicStarterCardTheme',
        fields: [
          field(
            'surfaceClassName',
            (t) => t.surfaceClassName,
            (t) => t.copyWith(surfaceClassName: 'changed'),
          ),
          field(
            'insetClassName',
            (t) => t.insetClassName,
            (t) => t.copyWith(insetClassName: 'changed'),
          ),
          field(
            'elevatedClassName',
            (t) => t.elevatedClassName,
            (t) => t.copyWith(elevatedClassName: 'changed'),
          ),
          field(
            'titleClassName',
            (t) => t.titleClassName,
            (t) => t.copyWith(titleClassName: 'changed'),
          ),
          field(
            'titleNoPaddingContainerClassName',
            (t) => t.titleNoPaddingContainerClassName,
            (t) => t.copyWith(titleNoPaddingContainerClassName: 'changed'),
          ),
          field(
            'borderRadius',
            (t) => t.borderRadius,
            (t) => t.copyWith(borderRadius: 'changed'),
          ),
          field(
            'paddingClassName',
            (t) => t.paddingClassName,
            (t) => t.copyWith(paddingClassName: 'changed'),
          ),
        ],
        original: const MagicStarterCardTheme(
          surfaceClassName: 'card-surface',
          insetClassName: 'card-inset',
          elevatedClassName: 'card-elevated',
          titleClassName: 'card-title',
          titleNoPaddingContainerClassName: 'card-title-no-padding',
          borderRadius: 'card-radius',
          paddingClassName: 'card-padding',
        ),
        defaults: const MagicStarterCardTheme(),
        copy: (t) => t.copyWith(),
      );
    });

    group('MagicStarterPageHeaderTheme', () {
      expectCopyWithComplete<MagicStarterPageHeaderTheme>(
        className: 'MagicStarterPageHeaderTheme',
        fields: [
          field(
            'containerClassName',
            (t) => t.containerClassName,
            (t) => t.copyWith(containerClassName: 'changed'),
          ),
          field(
            'containerInlineClassName',
            (t) => t.containerInlineClassName,
            (t) => t.copyWith(containerInlineClassName: 'changed'),
          ),
          field(
            'titleClassName',
            (t) => t.titleClassName,
            (t) => t.copyWith(titleClassName: 'changed'),
          ),
          field(
            'subtitleClassName',
            (t) => t.subtitleClassName,
            (t) => t.copyWith(subtitleClassName: 'changed'),
          ),
          field(
            'actionContainerClassName',
            (t) => t.actionContainerClassName,
            (t) => t.copyWith(actionContainerClassName: 'changed'),
          ),
          field(
            'backControlClassName',
            (t) => t.backControlClassName,
            (t) => t.copyWith(backControlClassName: 'changed'),
          ),
          field(
            'inlineActions',
            (t) => t.inlineActions,
            (t) => t.copyWith(inlineActions: false),
          ),
          field(
            'largeTitle',
            (t) => t.largeTitle,
            (t) => t.copyWith(largeTitle: false),
          ),
          field(
            'largeTitleClassName',
            (t) => t.largeTitleClassName,
            (t) => t.copyWith(largeTitleClassName: 'changed'),
          ),
          field(
            'compactBarClassName',
            (t) => t.compactBarClassName,
            (t) => t.copyWith(compactBarClassName: 'changed'),
          ),
          field(
            'compactBarOpaqueClassName',
            (t) => t.compactBarOpaqueClassName,
            (t) => t.copyWith(compactBarOpaqueClassName: 'changed'),
          ),
          field(
            'compactTitleClassName',
            (t) => t.compactTitleClassName,
            (t) => t.copyWith(compactTitleClassName: 'changed'),
          ),
          field(
            'compactBarBlurSigma',
            (t) => t.compactBarBlurSigma,
            (t) => t.copyWith(compactBarBlurSigma: 999.0),
          ),
        ],
        original: const MagicStarterPageHeaderTheme(
          containerClassName: 'header-container',
          containerInlineClassName: 'header-container-inline',
          titleClassName: 'header-title',
          subtitleClassName: 'header-subtitle',
          actionContainerClassName: 'header-actions',
          backControlClassName: 'header-back',
          inlineActions: true,
          largeTitle: true,
          largeTitleClassName: 'header-large-title',
          compactBarClassName: 'header-compact-bar',
          compactBarOpaqueClassName: 'header-compact-bar-opaque',
          compactTitleClassName: 'header-compact-title',
          compactBarBlurSigma: 7.0,
        ),
        defaults: const MagicStarterPageHeaderTheme(),
        copy: (t) => t.copyWith(),
      );
    });

    group('MagicStarterLayoutTheme', () {
      expectCopyWithComplete<MagicStarterLayoutTheme>(
        className: 'MagicStarterLayoutTheme',
        fields: [
          field(
            'sidebarClassName',
            (t) => t.sidebarClassName,
            (t) => t.copyWith(sidebarClassName: 'changed'),
          ),
          field(
            'sidebarWidth',
            (t) => t.sidebarWidth,
            (t) => t.copyWith(sidebarWidth: 999.0),
          ),
          field(
            'navigationBreakpoint',
            (t) => t.navigationBreakpoint,
            (t) => t.copyWith(navigationBreakpoint: 'changed'),
          ),
          field(
            'sidebarExpandedBreakpoint',
            (t) => t.sidebarExpandedBreakpoint,
            (t) => t.copyWith(sidebarExpandedBreakpoint: 'changed'),
          ),
          field(
            'sidebarCompactWidth',
            (t) => t.sidebarCompactWidth,
            (t) => t.copyWith(sidebarCompactWidth: 999.0),
          ),
          field(
            'sidebarCollapsible',
            (t) => t.sidebarCollapsible,
            (t) => t.copyWith(sidebarCollapsible: false),
          ),
          field(
            'sidebarCollapsedByDefault',
            (t) => t.sidebarCollapsedByDefault,
            (t) => t.copyWith(sidebarCollapsedByDefault: false),
          ),
          field(
            'headerClassName',
            (t) => t.headerClassName,
            (t) => t.copyWith(headerClassName: 'changed'),
          ),
          field(
            'headerHeight',
            (t) => t.headerHeight,
            (t) => t.copyWith(headerHeight: 999.0),
          ),
          field(
            'contentBackgroundLightColor',
            (t) => t.contentBackgroundLightColor,
            (t) => t.copyWith(contentBackgroundLightColor: 'changed'),
          ),
          field(
            'contentBackgroundLightShade',
            (t) => t.contentBackgroundLightShade,
            (t) => t.copyWith(contentBackgroundLightShade: 999),
          ),
          field(
            'contentBackgroundDarkColor',
            (t) => t.contentBackgroundDarkColor,
            (t) => t.copyWith(contentBackgroundDarkColor: 'changed'),
          ),
          field(
            'contentBackgroundDarkShade',
            (t) => t.contentBackgroundDarkShade,
            (t) => t.copyWith(contentBackgroundDarkShade: 999),
          ),
          field(
            'drawerBackgroundLightColor',
            (t) => t.drawerBackgroundLightColor,
            (t) => t.copyWith(drawerBackgroundLightColor: 'changed'),
          ),
          field(
            'drawerBackgroundLightShade',
            (t) => t.drawerBackgroundLightShade,
            (t) => t.copyWith(drawerBackgroundLightShade: 999),
          ),
          field(
            'drawerBackgroundDarkColor',
            (t) => t.drawerBackgroundDarkColor,
            (t) => t.copyWith(drawerBackgroundDarkColor: 'changed'),
          ),
          field(
            'drawerBackgroundDarkShade',
            (t) => t.drawerBackgroundDarkShade,
            (t) => t.copyWith(drawerBackgroundDarkShade: 999),
          ),
          field(
            'brandBarClassName',
            (t) => t.brandBarClassName,
            (t) => t.copyWith(brandBarClassName: 'changed'),
          ),
          field(
            'bottomNavClassName',
            (t) => t.bottomNavClassName,
            (t) => t.copyWith(bottomNavClassName: 'changed'),
          ),
          field(
            'contentClassName',
            (t) => t.contentClassName,
            (t) => t.copyWith(contentClassName: 'changed'),
          ),
          field(
            'contentScrollPrimary',
            (t) => t.contentScrollPrimary,
            (t) => t.copyWith(contentScrollPrimary: false),
          ),
          field(
            'notificationTriggerClassName',
            (t) => t.notificationTriggerClassName,
            (t) => t.copyWith(notificationTriggerClassName: 'changed'),
          ),
          field(
            'notificationTriggerIconClassName',
            (t) => t.notificationTriggerIconClassName,
            (t) => t.copyWith(notificationTriggerIconClassName: 'changed'),
          ),
          field(
            'notificationPanelClassName',
            (t) => t.notificationPanelClassName,
            (t) => t.copyWith(notificationPanelClassName: 'changed'),
          ),
          field(
            'notificationBadgeClassName',
            (t) => t.notificationBadgeClassName,
            (t) => t.copyWith(notificationBadgeClassName: 'changed'),
          ),
          field(
            'notificationBadgeTextClassName',
            (t) => t.notificationBadgeTextClassName,
            (t) => t.copyWith(notificationBadgeTextClassName: 'changed'),
          ),
        ],
        original: const MagicStarterLayoutTheme(
          sidebarClassName: 'layout-sidebar',
          sidebarWidth: 301.0,
          navigationBreakpoint: 'layout-nav-bp',
          sidebarExpandedBreakpoint: 'layout-expanded-bp',
          sidebarCompactWidth: 71.0,
          sidebarCollapsible: true,
          sidebarCollapsedByDefault: true,
          headerClassName: 'layout-header',
          headerHeight: 57.0,
          contentBackgroundLightColor: 'layout-content-light',
          contentBackgroundLightShade: 51,
          contentBackgroundDarkColor: 'layout-content-dark',
          contentBackgroundDarkShade: 952,
          drawerBackgroundLightColor: 'layout-drawer-light',
          drawerBackgroundLightShade: 53,
          drawerBackgroundDarkColor: 'layout-drawer-dark',
          drawerBackgroundDarkShade: 954,
          brandBarClassName: 'layout-brand-bar',
          bottomNavClassName: 'layout-bottom-nav',
          contentClassName: 'layout-content',
          contentScrollPrimary: true,
          notificationTriggerClassName: 'layout-bell-trigger',
          notificationTriggerIconClassName: 'layout-bell-icon',
          notificationPanelClassName: 'layout-bell-panel',
          notificationBadgeClassName: 'layout-bell-badge',
          notificationBadgeTextClassName: 'layout-bell-badge-text',
        ),
        defaults: const MagicStarterLayoutTheme(),
        copy: (t) => t.copyWith(),
      );
    });

    group('MagicStarterAuthTheme', () {
      expectCopyWithComplete<MagicStarterAuthTheme>(
        className: 'MagicStarterAuthTheme',
        fields: [
          field(
            'cardClassName',
            (t) => t.cardClassName,
            (t) => t.copyWith(cardClassName: 'changed'),
          ),
          field(
            'titleClassName',
            (t) => t.titleClassName,
            (t) => t.copyWith(titleClassName: 'changed'),
          ),
          field(
            'subtitleClassName',
            (t) => t.subtitleClassName,
            (t) => t.copyWith(subtitleClassName: 'changed'),
          ),
          field(
            'errorBannerClassName',
            (t) => t.errorBannerClassName,
            (t) => t.copyWith(errorBannerClassName: 'changed'),
          ),
          field(
            'themeToggleClassName',
            (t) => t.themeToggleClassName,
            (t) => t.copyWith(themeToggleClassName: 'changed'),
          ),
          field(
            'themeToggleIconClassName',
            (t) => t.themeToggleIconClassName,
            (t) => t.copyWith(themeToggleIconClassName: 'changed'),
          ),
          field(
            'socialDividerClassName',
            (t) => t.socialDividerClassName,
            (t) => t.copyWith(socialDividerClassName: 'changed'),
          ),
          field(
            'socialDividerLineClassName',
            (t) => t.socialDividerLineClassName,
            (t) => t.copyWith(socialDividerLineClassName: 'changed'),
          ),
          field(
            'socialDividerTextClassName',
            (t) => t.socialDividerTextClassName,
            (t) => t.copyWith(socialDividerTextClassName: 'changed'),
          ),
          field(
            'guestButtonClassName',
            (t) => t.guestButtonClassName,
            (t) => t.copyWith(guestButtonClassName: 'changed'),
          ),
          field(
            'registrationLinkClassName',
            (t) => t.registrationLinkClassName,
            (t) => t.copyWith(registrationLinkClassName: 'changed'),
          ),
          field(
            'registrationLinkTextClassName',
            (t) => t.registrationLinkTextClassName,
            (t) => t.copyWith(registrationLinkTextClassName: 'changed'),
          ),
        ],
        original: const MagicStarterAuthTheme(
          cardClassName: 'auth-card',
          titleClassName: 'auth-title',
          subtitleClassName: 'auth-subtitle',
          errorBannerClassName: 'auth-error',
          themeToggleClassName: 'auth-toggle',
          themeToggleIconClassName: 'auth-toggle-icon',
          socialDividerClassName: 'auth-divider',
          socialDividerLineClassName: 'auth-divider-line',
          socialDividerTextClassName: 'auth-divider-text',
          guestButtonClassName: 'auth-guest',
          registrationLinkClassName: 'auth-registration',
          registrationLinkTextClassName: 'auth-registration-text',
        ),
        defaults: const MagicStarterAuthTheme(),
        copy: (t) => t.copyWith(),
      );
    });

    group('MagicStarterDropdownTheme', () {
      expectCopyWithComplete<MagicStarterDropdownTheme>(
        className: 'MagicStarterDropdownTheme',
        fields: [
          field(
            'panelClassName',
            (t) => t.panelClassName,
            (t) => t.copyWith(panelClassName: 'changed'),
          ),
          field(
            'dividerClassName',
            (t) => t.dividerClassName,
            (t) => t.copyWith(dividerClassName: 'changed'),
          ),
          field(
            'itemClassName',
            (t) => t.itemClassName,
            (t) => t.copyWith(itemClassName: 'changed'),
          ),
          field(
            'tileClassName',
            (t) => t.tileClassName,
            (t) => t.copyWith(tileClassName: 'changed'),
          ),
          field(
            'textClassName',
            (t) => t.textClassName,
            (t) => t.copyWith(textClassName: 'changed'),
          ),
          field(
            'mutedTextClassName',
            (t) => t.mutedTextClassName,
            (t) => t.copyWith(mutedTextClassName: 'changed'),
          ),
          field(
            'dangerTextClassName',
            (t) => t.dangerTextClassName,
            (t) => t.copyWith(dangerTextClassName: 'changed'),
          ),
          field(
            'dangerTileClassName',
            (t) => t.dangerTileClassName,
            (t) => t.copyWith(dangerTileClassName: 'changed'),
          ),
        ],
        original: const MagicStarterDropdownTheme(
          panelClassName: 'dropdown-panel',
          dividerClassName: 'dropdown-divider',
          itemClassName: 'dropdown-item',
          tileClassName: 'dropdown-tile',
          textClassName: 'dropdown-text',
          mutedTextClassName: 'dropdown-muted',
          dangerTextClassName: 'dropdown-danger-text',
          dangerTileClassName: 'dropdown-danger-tile',
        ),
        defaults: const MagicStarterDropdownTheme(),
        copy: (t) => t.copyWith(),
      );
    });

    group('MagicStarterButtonTheme', () {
      expectCopyWithComplete<MagicStarterButtonTheme>(
        className: 'MagicStarterButtonTheme',
        fields: [
          field(
            'shapeClassName',
            (t) => t.shapeClassName,
            (t) => t.copyWith(shapeClassName: 'changed'),
          ),
          field(
            'smClassName',
            (t) => t.smClassName,
            (t) => t.copyWith(smClassName: 'changed'),
          ),
          field(
            'mdClassName',
            (t) => t.mdClassName,
            (t) => t.copyWith(mdClassName: 'changed'),
          ),
          field(
            'lgClassName',
            (t) => t.lgClassName,
            (t) => t.copyWith(lgClassName: 'changed'),
          ),
          field(
            'secondaryBorderClassName',
            (t) => t.secondaryBorderClassName,
            (t) => t.copyWith(secondaryBorderClassName: 'changed'),
          ),
        ],
        original: const MagicStarterButtonTheme(
          shapeClassName: 'button-shape',
          smClassName: 'button-sm',
          mdClassName: 'button-md',
          lgClassName: 'button-lg',
          secondaryBorderClassName: 'button-border',
        ),
        defaults: const MagicStarterButtonTheme(),
        copy: (t) => t.copyWith(),
      );
    });

    group('MagicStarterFieldTheme', () {
      expectCopyWithComplete<MagicStarterFieldTheme>(
        className: 'MagicStarterFieldTheme',
        fields: [
          field(
            'inputSizeClassName',
            (t) => t.inputSizeClassName,
            (t) => t.copyWith(inputSizeClassName: 'changed'),
          ),
          field(
            'selectSizeClassName',
            (t) => t.selectSizeClassName,
            (t) => t.copyWith(selectSizeClassName: 'changed'),
          ),
          field(
            'segmentedSmClassName',
            (t) => t.segmentedSmClassName,
            (t) => t.copyWith(segmentedSmClassName: 'changed'),
          ),
          field(
            'segmentedMdClassName',
            (t) => t.segmentedMdClassName,
            (t) => t.copyWith(segmentedMdClassName: 'changed'),
          ),
          field(
            'segmentedPaddingClassName',
            (t) => t.segmentedPaddingClassName,
            (t) => t.copyWith(segmentedPaddingClassName: 'changed'),
          ),
        ],
        original: const MagicStarterFieldTheme(
          inputSizeClassName: 'field-input',
          selectSizeClassName: 'field-select',
          segmentedSmClassName: 'field-segmented-sm',
          segmentedMdClassName: 'field-segmented-md',
          segmentedPaddingClassName: 'field-segmented-padding',
        ),
        defaults: const MagicStarterFieldTheme(),
        copy: (t) => t.copyWith(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // applyWindTheme: every field goes through the merge
  // -------------------------------------------------------------------------

  // `MagicStarterManager.applyWindTheme` rebuilds each sub-theme field by
  // field, and a named parameter it leaves out compiles and quietly falls back
  // to the stock default: a host field set before `useWindTheme` would then be
  // lost again, the defect #149 fixed. The constructors are the list to hold
  // the merge to.
  group('the Wind theme merge', () {
    final theme = File('lib/src/configuration/magic_starter_theme.dart')
        .readAsStringSync();
    final manager = File('lib/src/magic_starter_manager.dart')
        .readAsStringSync();

    Set<String> namesIn(
      String source,
      String opening,
      RegExp name, {
      String closing = '\n  });',
    }) {
      final start = source.indexOf(opening);
      final end = source.indexOf(closing, start);
      final close = end < 0 ? source.indexOf('\n}', start) : end;

      expect(start, isNonNegative, reason: 'no "$opening"');

      return name
          .allMatches(source.substring(start, close))
          .map((m) => m.group(1)!)
          .toSet();
    }

    for (final (className, merge) in const [
      ('MagicStarterNavigationTheme', '_mergeNavigation'),
      ('MagicStarterModalTheme', '_mergeModal'),
      ('MagicStarterFormTheme', '_mergeForm'),
      ('MagicStarterCardTheme', '_mergeCard'),
      ('MagicStarterPageHeaderTheme', '_mergePageHeader'),
      ('MagicStarterLayoutTheme', '_mergeLayout'),
      ('MagicStarterAuthTheme', '_mergeAuth'),
      ('MagicStarterDropdownTheme', '_mergeDropdown'),
      ('MagicStarterButtonTheme', '_mergeButton'),
      ('MagicStarterFieldTheme', '_mergeField'),
    ]) {
      test('$merge picks every field of $className', () {
        final fields = namesIn(
          theme,
          '  const $className({',
          RegExp(r'this\.(\w+)'),
        );
        final picked = namesIn(
          manager,
          '$className $merge(',
          // A picked field, or one of a pair picked into a local first.
          RegExp(r'(\w+): (?:m\.pick|[a-z]\w*,)'),
        );

        expect(picked, fields);
      });
    }

    // The ten pairs above are written by hand, so a sub-theme added to
    // `MagicStarterTheme` without a merge would pass them all and then be
    // reset to its default by every `useWindTheme`.
    test('applyWindTheme merges every sub-theme of MagicStarterTheme', () {
      final subThemes = namesIn(
        theme,
        '  const MagicStarterTheme({',
        RegExp(r'this\.(\w+)'),
      );
      final merged = namesIn(
        manager,
        'merge(bool record) => MagicStarterTheme(',
        RegExp(r'(\w+): _merge\w+\('),
        closing: '\n    );',
      );

      expect(merged, subThemes);
    });
  });

  // -------------------------------------------------------------------------
  // fromWind: drawer and content backgrounds
  // -------------------------------------------------------------------------

  // The two pairs are `wColor` keys rather than classNames, so `fromWind`
  // reads them out of the `bg-surface` role the sidebar and the header are
  // derived from: a host palette that is not grey otherwise gets a drawer and
  // a content area in stock greys beside its own sidebar.
  group('MagicStarterTheme.fromWind backgrounds', () {
    const ink = MaterialColor(0xFF223344, <int, Color>{
      50: Color(0xFFF1F2F4),
      500: Color(0xFF223344),
      950: Color(0xFF0E0F11),
    });

    test('derives both pairs from a palette surface', () {
      final layout = MagicStarterTheme.fromWind(
        WindThemeData(
          colors: const {'ink': ink},
          aliases: const {'bg-surface': 'bg-ink-50 dark:bg-ink-950'},
        ),
      ).layout;

      expect(layout.contentBackgroundLightColor, 'ink');
      expect(layout.contentBackgroundLightShade, 50);
      expect(layout.contentBackgroundDarkColor, 'ink');
      expect(layout.contentBackgroundDarkShade, 950);
      expect(layout.drawerBackgroundLightColor, 'ink');
      expect(layout.drawerBackgroundLightShade, 50);
      expect(layout.drawerBackgroundDarkColor, 'ink');
      expect(layout.drawerBackgroundDarkShade, 950);
    });

    test('derives both pairs from an arbitrary hex surface', () {
      final layout = MagicStarterTheme.fromWind(
        WindThemeData(
          aliases: const {'bg-surface': 'bg-[#F7F7F8] dark:bg-[#0E0F11]'},
        ),
      ).layout;

      expect(layout.contentBackgroundLightColor, '#F7F7F8');
      expect(layout.contentBackgroundDarkColor, '#0E0F11');
      expect(layout.drawerBackgroundLightColor, '#F7F7F8');
      expect(layout.drawerBackgroundDarkColor, '#0E0F11');
    });

    // Wind paints the last background utility of a brightness, so a surface
    // role that names two must be read the same way or the content and
    // drawer drift from the sidebar painted with the role itself.
    testWidgets('reads the last background of each brightness, as Wind does', (
      tester,
    ) async {
      const sky = MaterialColor(0xFF3366AA, <int, Color>{
        200: Color(0xFFAACCEE),
        900: Color(0xFF112244),
      });
      final wind = WindThemeData(
        colors: const {'ink': ink, 'sky': sky},
        aliases: const {
          'bg-surface': 'bg-ink-50 bg-sky-200 dark:bg-ink-500 dark:bg-sky-900',
        },
      );
      Color? painted;
      await tester.pumpWidget(
        WindTheme(
          data: wind,
          child: Builder(
            builder: (context) {
              painted = WindParser.parse(
                'bg-surface',
                context,
              ).decoration?.color;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(painted, const Color(0xFFAACCEE), reason: 'Wind paints sky-200');

      final layout = MagicStarterTheme.fromWind(wind).layout;

      expect(layout.contentBackgroundLightColor, 'sky');
      expect(layout.contentBackgroundLightShade, 200);
      expect(layout.contentBackgroundDarkColor, 'sky');
      expect(layout.contentBackgroundDarkShade, 900);
      expect(layout.drawerBackgroundLightColor, 'sky');
      expect(layout.drawerBackgroundDarkShade, 900);
    });

    test('reads the last hex background, and reuses it for dark mode', () {
      final layout = MagicStarterTheme.fromWind(
        WindThemeData(
          aliases: const {'bg-surface': 'bg-[#F7F7F8] bg-[#EEEEF0]'},
        ),
      ).layout;

      expect(layout.contentBackgroundLightColor, '#EEEEF0');
      expect(layout.contentBackgroundDarkColor, '#EEEEF0');
    });

    test('uses the light surface in dark mode when it names no dark one', () {
      final layout = MagicStarterTheme.fromWind(
        WindThemeData(
          colors: const {'ink': ink},
          aliases: const {'bg-surface': 'bg-ink-950'},
        ),
      ).layout;

      expect(layout.drawerBackgroundDarkColor, 'ink');
      expect(layout.drawerBackgroundDarkShade, 950);
    });

    test(
      'keeps the stock pairs when the theme does not define the surface',
      () {
        final layout = MagicStarterTheme.fromWind(WindThemeData()).layout;
        const stock = MagicStarterLayoutTheme();

        expect(
          layout.contentBackgroundLightColor,
          stock.contentBackgroundLightColor,
        );
        expect(
          layout.contentBackgroundLightShade,
          stock.contentBackgroundLightShade,
        );
        expect(
          layout.contentBackgroundDarkColor,
          stock.contentBackgroundDarkColor,
        );
        expect(
          layout.contentBackgroundDarkShade,
          stock.contentBackgroundDarkShade,
        );
        expect(
          layout.drawerBackgroundLightColor,
          stock.drawerBackgroundLightColor,
        );
        expect(
          layout.drawerBackgroundDarkColor,
          stock.drawerBackgroundDarkColor,
        );
        expect(
          layout.drawerBackgroundDarkShade,
          stock.drawerBackgroundDarkShade,
        );
      },
    );

    test('keeps the stock half a surface names in a colour Wind lacks', () {
      // A role written in a palette key the theme does not carry resolves to
      // nothing, which would leave the drawer transparent; that half stays on
      // the shipped pair instead.
      final layout = MagicStarterTheme.fromWind(
        WindThemeData(
          colors: const {'ink': ink},
          aliases: const {'bg-surface': 'bg-ink-50 dark:bg-mist-900'},
        ),
      ).layout;
      const stock = MagicStarterLayoutTheme();

      expect(layout.drawerBackgroundLightColor, 'ink');
      expect(layout.drawerBackgroundDarkColor, stock.drawerBackgroundDarkColor);
      expect(layout.drawerBackgroundDarkShade, stock.drawerBackgroundDarkShade);
    });

    for (final brightness in Brightness.values) {
      testWidgets('resolves a derived hex surface in ${brightness.name} mode', (
        tester,
      ) async {
        final layout = MagicStarterTheme.fromWind(
          WindThemeData(
            aliases: const {'bg-surface': 'bg-[#F7F7F8] dark:bg-[#0E0F11]'},
          ),
        ).layout;
        late Color? content;
        late Color? drawer;

        await tester.pumpWidget(
          WindTheme(
            data: WindThemeData(brightness: brightness, syncWithSystem: false),
            child: Builder(
              builder: (context) {
                content = layout.contentBackgroundColor(context);
                drawer = layout.drawerBackgroundColor(context);

                return const SizedBox();
              },
            ),
          ),
        );

        final expected = brightness == Brightness.dark
            ? const Color(0xFF0E0F11)
            : const Color(0xFFF7F7F8);
        expect(content, expected);
        expect(drawer, expected);
      });
    }
  });
}

Widget _brandBuilder(BuildContext context) => const SizedBox();

Widget _compactBrandBuilder(BuildContext context) => const SizedBox();

Widget _changedBuilder(BuildContext context) => const SizedBox();

/// One field of a theme under test: how to read it, and how to set it through
/// `copyWith` to a value no distinct test theme uses.
class _Field<T> {
  final String name;
  final Object? Function(T) read;
  final T Function(T) change;

  const _Field(this.name, this.read, this.change);
}
