import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../Provider/VisitedCountriesProvider.dart';

class CountriesIVisitedScreen extends StatefulWidget {
  const CountriesIVisitedScreen({super.key});

  @override
  State<CountriesIVisitedScreen> createState() =>
      _CountriesIVisitedScreenState();
}

class _CountriesIVisitedScreenState extends State<CountriesIVisitedScreen> {
  Timer? _searchDebouncer;
  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();

    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      context.read<VisitedCountriesProvider>().searchCountries(query);
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VisitedCountriesProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: _buildAppBar(provider),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: context.screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!provider.isSelectionMode) _buildSearchSection(),
              // if (provider.isSelectionMode) _buildSelectionHeader(provider),
              const SizedBox(height: 24),
              _buildVisitedCountriesList(),
              if (provider.isSelectionMode) _buildRemoveSelectedButton(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Countries', style: pjsStyleBlack14500),
        const SizedBox(height: 8),
        Selector<VisitedCountriesProvider, TextEditingController>(
          selector: (_, provider) => provider.searchController,
          builder: (context, controller, _) => _buildSearchTextField(controller),
        ),
        Selector<VisitedCountriesProvider, List<Map<String, String>>>(
          selector: (_, provider) => provider.searchResults,
          builder: (context, searchResults, _) {
            if (searchResults.isNotEmpty) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearchResults(searchResults),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildSearchTextField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gray20,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Selector<VisitedCountriesProvider, bool>(
              selector: (_, provider) => provider.isSearching,
              builder: (context, isSearching, _) => isSearching
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : SvgPicture.asset(AppImages.searchMember),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for a country...',
                border: InputBorder.none,
                hintStyle: pjsStyleBlack14400.copyWith(
                  color: AppColors.garyModern400,
                ),
              ),
              style: pStyleBlack12400.copyWith(
                color: AppColors.black,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                context.read<VisitedCountriesProvider>().clearSelection();
              },
              icon: Icon(Icons.clear, color: AppColors.garyModern400, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Map<String, String>> searchResults) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(4),
        itemCount: searchResults.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: AppColors.gray20),
        itemBuilder: (context, index) {
          final country = searchResults[index];
          return Consumer<VisitedCountriesProvider>(
            builder: (context, provider, _) {
              final isBeingAdded = provider.isCountryBeingAdded(country['name']!);

              return ListTile(
                leading: Text(
                  country['flag']!,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(country['name']!, style: pjsStyleBlack14400),
                trailing: isBeingAdded
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 20,
                      ),
                onTap: isBeingAdded ? null : () async {
                  final result = await provider.addCountryDirectly(
                    country['name']!,
                    country['flag']!,
                  );
                  if (context.mounted) {
                    // Clear search results and text field after successful addition
                    if (result.contains('successfully')) {
                      provider.clearSelection();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result),
                        backgroundColor: result.contains('successfully')
                            ? Colors.green
                            : result.contains('Please wait')
                                ? Colors.orange
                                : Colors.red,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(VisitedCountriesProvider provider) {
    if (provider.isSelectionMode) {
      return AppBar(
        title: Text(
          '${provider.selectedCount} Selected',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
        centerTitle: true,
        backgroundColor: AppColors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: AppColors.lightGrey.withOpacity(0.60),
            child: IconButton(
              icon: Icon(Icons.close, color: AppColors.black),
              onPressed: () => provider.exitSelectionMode(),
            ),
          ),
        ),

        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: provider.getVisitedCountriesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final allCountryIds = snapshot.data!.docs.map((doc) => doc.id).toList();
              final isAllSelected = provider.selectedCount == allCountryIds.length && allCountryIds.isNotEmpty;

              return TextButton(
                onPressed: () {
                  if (isAllSelected) {
                    provider.deselectAllCountries();
                  } else {
                    provider.selectAllCountries(allCountryIds);
                  }
                },
                child: Text(
                  isAllSelected ? 'Deselect All' : 'Select All',
                  style: TextStyle(color: AppColors.primary),
                ),
              );
            },
          ),
        ],
      );
    }

    return AppBar(
      title: Text(
        "Countries I've Visited",
        style: pjsStyleBlack18600.copyWith(color: AppColors.black),
      ),
      backgroundColor: AppColors.white,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: CircleAvatar(
          backgroundColor: AppColors.lightGrey.withOpacity(0.60),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
     centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.checklist, color: AppColors.black),
          onPressed: () => provider.toggleSelectionMode(),
          tooltip: 'Select multiple countries',
        ),
      ],
    );
  }

  // Widget _buildSelectionHeader(VisitedCountriesProvider provider) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppColors.primary.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: AppColors.primary.withOpacity(0.3)),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(Icons.info_outline, color: AppColors.primary, size: 20),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: Text(
  //             'Tap countries to select them for deletion',
  //             style: pjsStyleBlack12400.copyWith(color: AppColors.primary),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRemoveSelectedButton(VisitedCountriesProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.selectedCount > 0
            ? () => _showBatchDeleteConfirmation(provider)
            : null,
        icon: Icon(
          Icons.delete,
          color: provider.selectedCount > 0 ? Colors.white : AppColors.garyModern400,
        ),
        label: Text(
          'Remove Selected (${provider.selectedCount})',
          style: TextStyle(
            color: provider.selectedCount > 0 ? Colors.white : AppColors.garyModern400,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: provider.selectedCount > 0
              ? Colors.red.shade600
              : AppColors.garyModern200,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitedCountriesList() {
    return const VisitedCountriesListWidget();
  }

  Widget _buildCountryTile(
    String docId,
    String countryName,
    String countryFlag,
    VisitedCountriesProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ListTile(
            leading: Text(countryFlag, style: const TextStyle(fontSize: 24)),
            title: Text(countryName, style: pjsStyleBlack14400),
            trailing: IconButton(
              onPressed: () =>
                  _showDeleteConfirmation(docId, countryName, provider),
              icon: Icon(Icons.close, size: 18, color: AppColors.garyModern400),
              tooltip: 'Remove country',
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.garyModern200,
          highlightColor: AppColors.white,
          child: Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) => _buildShimmerCountryTile(),
        ),
      ],
    );
  }

  Widget _buildShimmerCountryTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.garyModern200,
        highlightColor: AppColors.white,
        child: ListTile(
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          trailing: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 64, color: AppColors.garyModern200),
          const SizedBox(height: 16),
          Text(
            'No countries visited yet',
            style: pjsStyleBlack16500.copyWith(color: AppColors.garyModern500),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for countries you\'ve visited\nand tap to add them to your travel list!',
            style: pjsStyleBlack12400.copyWith(color: AppColors.garyModern400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: pjsStyleBlack16500.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load your visited countries.\nPlease try again.',
            style: pjsStyleBlack12400.copyWith(color: AppColors.garyModern400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}), // Refresh the stream
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    String docId,
    String countryName,
    VisitedCountriesProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Country'),
        content: Text(
          'Are you sure you want to remove $countryName from your visited countries?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.garyModern500),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await provider.removeCountryFromVisited(docId);
              _showMessage(result, isError: !result.contains('successfully'));
            },
            child: Text('Remove', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }

  void _showBatchDeleteConfirmation(VisitedCountriesProvider provider) {
    final selectedCount = provider.selectedCount;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Selected Countries'),
        content: Text(
          'Are you sure you want to remove $selectedCount ${selectedCount == 1 ? 'country' : 'countries'} from your visited countries?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.garyModern500),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await provider.removeSelectedCountries();
              _showMessage(result, isError: !result.contains('successfully'));
            },
            child: Text('Remove All', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}

// Separate widget for visited countries list to prevent rebuilds
class VisitedCountriesListWidget extends StatefulWidget {
  const VisitedCountriesListWidget({Key? key}) : super(key: key);

  @override
  State<VisitedCountriesListWidget> createState() => _VisitedCountriesListWidgetState();
}

class _VisitedCountriesListWidgetState extends State<VisitedCountriesListWidget> {
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: context.read<VisitedCountriesProvider>().getVisitedCountriesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final countries = snapshot.data?.docs ?? [];

        if (countries.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Visited Countries (${countries.length})',
              style: pjsStyleBlack14500,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final doc = countries[index];
                final data = doc.data() as Map<String, dynamic>;
                final countryName = data['name'] ?? '';
                final countryFlag = data['flag'] ?? '🌍';
                return _buildCountryTile(
                  doc.id,
                  countryName,
                  countryFlag,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountryTile(
    String docId,
    String countryName,
    String countryFlag,
  ) {
    return Consumer<VisitedCountriesProvider>(
      builder: (context, provider, _) {
        final isSelected = provider.isCountrySelectedForDeletion(docId);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: provider.isSelectionMode && isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Color(0xFFEAF6FF),
            borderRadius: BorderRadius.circular(10),
            border: provider.isSelectionMode && isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: provider.isSelectionMode
              ? CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) => provider.toggleCountrySelection(docId),
                  secondary: Text(countryFlag, style: const TextStyle(fontSize: 24)),
                  title: Text(countryName, style: pjsStyleBlack14400),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  activeColor: AppColors.primary,
                )
              : ListTile(
                  leading: Text(countryFlag, style: const TextStyle(fontSize: 24)),
                  title: Text(countryName, style: pjsStyleBlack14400),
                  trailing: IconButton(
                    onPressed: () =>
                        _showDeleteConfirmation(docId, countryName),
                    icon: Icon(Icons.close, size: 18, color: AppColors.garyModern400),
                    tooltip: 'Remove country',
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.garyModern200,
          highlightColor: AppColors.white,
          child: Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) => _buildShimmerCountryTile(),
        ),
      ],
    );
  }

  Widget _buildShimmerCountryTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.garyModern200,
        highlightColor: AppColors.white,
        child: ListTile(
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          trailing: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.garyModern200,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 64, color: AppColors.garyModern200),
          const SizedBox(height: 16),
          Text(
            'No countries visited yet',
            style: pjsStyleBlack16500.copyWith(color: AppColors.garyModern500),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for countries you\'ve visited\nand tap to add them to your travel list!',
            style: pjsStyleBlack12400.copyWith(color: AppColors.garyModern400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: pjsStyleBlack16500.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load your visited countries.\nPlease try again.',
            style: pjsStyleBlack12400.copyWith(color: AppColors.garyModern400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}), // Refresh the stream
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    String docId,
    String countryName,
  ) {
    // Capture the provider reference before showing the dialog
    final provider = context.read<VisitedCountriesProvider>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          bool isDeleting = false;
          
          return AlertDialog(
            title: const Text('Remove Country'),
            content: Text(
              'Are you sure you want to remove $countryName from your visited countries?',
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDeleting ? AppColors.garyModern400 : AppColors.garyModern500,
                  ),
                ),
              ),
              TextButton(
                onPressed: isDeleting ? null : () async {
                  setState(() {
                    isDeleting = true;
                  });

                  print('🗑️ Starting deletion process...');
                  print('🆔 Document ID: $docId');
                  print('🏳️ Country Name: $countryName');
                  print('👤 Provider available: ${provider.runtimeType}');

                  try {
                    final result = await provider.removeCountryFromVisited(docId);
                    print('✅ Deletion result: $result');

                    if (mounted) {
                      Navigator.of(dialogContext).pop(); // Close dialog after successful deletion
                      _showMessage(result, isError: !result.contains('successfully'));
                    }
                  } catch (e) {
                    print('❌ Deletion failed with exception: $e');
                    setState(() {
                      isDeleting = false; // Re-enable button on error
                    });
                    if (mounted) {
                      _showMessage('Failed to delete country: $e', isError: true);
                    }
                  }
                },
                child: isDeleting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade600,
                        ),
                      )
                    : Text('Remove', style: TextStyle(color: Colors.red.shade600)),
              ),
            ],
          );
        },
      ),
    );
  }

}