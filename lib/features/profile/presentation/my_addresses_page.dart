import 'package:flutter/material.dart';

import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/address_service.dart';
import 'new_address_page.dart';
import 'widgets/account_components.dart';

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({super.key});

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  final _addressService = AddressService.instance;

  void _openAddAddress() {
    if (!_addressService.canAddAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have reached the 10-address limit. Edit or remove an address before adding another.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const NewAddressPage()),
    );
  }

  void _openEditAddress(AddressModel address) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NewAddressPage(editAddress: address),
      ),
    );
  }

  void _setDefault(AddressModel address) {
    if (address.isDefault) return;
    _addressService.setDefaultAddress(address.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${address.fullName} is now your default address.'),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('How delivery addresses work'),
        content: const Text(
          'Your default address is selected automatically at checkout. You can still choose another saved address before placing an order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _addressService,
      builder: (context, _) {
        final addresses = _addressService.addresses;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My addresses'),
            actions: [
              IconButton(
                tooltip: 'About delivery addresses',
                onPressed: _showInfoDialog,
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
          body: CustomScrollView(
            key: const Key('addresses-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  NexoraSpacing.md,
                  NexoraSpacing.xs,
                  NexoraSpacing.md,
                  NexoraSpacing.xl,
                ),
                sliver: SliverList.list(
                  children: [
                    AccountSection(
                      title: 'Delivery addresses',
                      description: addresses.isEmpty
                          ? 'Saved addresses will appear here.'
                          : 'Tap an address to make it the default.',
                      child: addresses.isEmpty
                          ? const AccountPanel(
                              child: AccountEmptyState(
                                icon: Icons.location_off_outlined,
                                title: 'No saved addresses',
                                message: 'Add a complete address and delivery pin for reliable courier handoff.',
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < addresses.length; i++) ...[
                                  _AddressCard(
                                    key: ValueKey(addresses[i].id),
                                    address: addresses[i],
                                    onTap: () => _setDefault(addresses[i]),
                                    onEdit: () =>
                                        _openEditAddress(addresses[i]),
                                  ),
                                  if (i != addresses.length - 1)
                                    const SizedBox(height: NexoraSpacing.sm),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: AccountBottomActionBar(
            child: FilledButton.icon(
              key: const Key('add-address-action'),
              onPressed: _openAddAddress,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _addressService.canAddAddress
                    ? 'Add delivery address'
                    : 'Address limit reached',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    super.key,
    required this.address,
    required this.onTap,
    required this.onEdit,
  });

  final AddressModel address;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 350 || textScale > 1.3;

    return Semantics(
      button: !address.isDefault,
      selected: address.isDefault,
      label:
          '${address.fullName}, ${address.fullAddress}, ${address.phone}${address.isDefault ? ', default address' : ''}',
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.card),
          side: BorderSide(
            color: address.isDefault
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: address.isDefault ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(NexoraSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact) ...[
                  Text(address.fullName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: NexoraSpacing.xxs),
                  Text(address.phone, style: theme.textTheme.bodySmall),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.fullName,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: NexoraSpacing.xxs),
                            Text(
                              address.phone,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                const SizedBox(height: NexoraSpacing.sm),
                Text(
                  address.fullAddress,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: NexoraSpacing.sm),
                Wrap(
                  spacing: NexoraSpacing.xs,
                  runSpacing: NexoraSpacing.xs,
                  children: [
                    if (address.isDefault)
                      const Chip(
                        avatar: Icon(Icons.check_circle_rounded, size: 16),
                        label: Text('Default'),
                      ),
                    Chip(label: Text(address.label)),
                    if (address.latitude != null && address.longitude != null)
                      const Chip(
                        avatar: Icon(Icons.location_on_outlined, size: 16),
                        label: Text('Pin saved'),
                      ),
                  ],
                ),
                if (!address.isDefault) ...[
                  const SizedBox(height: NexoraSpacing.xs),
                  Text(
                    'Tap to use as default',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
