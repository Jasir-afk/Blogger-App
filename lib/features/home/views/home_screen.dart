import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_project/core/routes/app_routes.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:test_project/features/blog/controllers/blog_controller.dart';
import 'package:test_project/features/blog/models/blog_model.dart';
import 'package:intl/intl.dart';
import 'package:test_project/features/home/widgets/custom_bottom_nav.dart';
import 'package:test_project/features/profile/views/profile_screen.dart';
import 'package:test_project/features/auth/controllers/auth_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final blogController = Get.find<BlogController>();
  final authController = Get.find<AuthController>();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _bottomNavIndex = 0;
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Tech',
    'Lifestyle',
    'Food',
    'Travel',
    'Health',
    'Business',
    'Fashion',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    // Fetch the initial category (All) from the local API on load
    blogController.fetchBlogsByCategory(_categories[0]);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final category = _categories[_tabController.index];
        if (_searchQuery.isEmpty) {
          blogController.fetchBlogsByCategory(category, isLoadMore: true);
        }
      }
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });
        // Fetch from local API for the newly selected category
        final selectedCategory = _categories[_tabController.index];
        blogController.fetchBlogsByCategory(selectedCategory);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: _bottomNavIndex == 0
          ? AppBar(
              backgroundColor: AppColors.scaffoldBg,
              elevation: 0,
              toolbarHeight: 80,
              centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      'Hello, ${authController.userName.value} 👋',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Blogger',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: () => setState(() => _bottomNavIndex = 1),
                  child: Obx(() {
                    final imageUrl = authController.userProfileImage.value;
                    ImageProvider provider;

                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      if (imageUrl.startsWith('http')) {
                        provider = NetworkImage(imageUrl);
                      } else {
                        provider = FileImage(File(imageUrl));
                      }
                    } else {
                      provider = NetworkImage(
                        'https://ui-avatars.com/api/?name=${authController.userName.value}&background=D946EF&color=fff',
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(right: 20),
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: provider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: _categories.map((cat) => Tab(text: cat)).toList(),
              ),
            )
          : null,
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          TabBarView(
            controller: _tabController,
            children: _categories.map((cat) => _buildHomeFeed(cat)).toList(),
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() => _bottomNavIndex = index);
        },
        onAddTap: () async {
          final result = await Get.toNamed(AppRoutes.addBlog);

          if (result != null && result['success'] == true) {
            final category = result['category'] as String;
            final categoryIndex = _categories.indexOf(category);

            // 1. Switch to Home tab and clear search
            setState(() {
              _bottomNavIndex = 0;
              _searchQuery = '';
              _searchController.clear();
            });

            // 2. Show Success Snackbar
            Get.snackbar(
              'Published',
              'Your story is now live in the $category feed!',
              snackPosition: SnackPosition.TOP,
              backgroundColor: AppColors.primaryColor.withOpacity(0.9),
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              duration: const Duration(seconds: 4),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
            );

            // 3. Animate to the specific category tab after the UI has switched
            if (categoryIndex != -1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _tabController.animateTo(
                      categoryIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildHomeFeed(String category) {
    return RefreshIndicator(
      onRefresh: () async => blogController.fetchBlogsByCategory(category),
      color: AppColors.primaryColor,
      child: Obx(() {
        if (blogController.isCategoryLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        } else if (blogController.categoryError.isNotEmpty) {
          return _buildErrorState(blogController.categoryError.value);
        } else if (blogController.categoryBlogs.isEmpty) {
          return const Center(
            child: Text(
              'No blogs found.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        final List<BlogModel> allBlogs = blogController.categoryBlogs;
        final List<BlogModel> blogs = allBlogs.where((blog) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              blog.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              blog.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          return matchesSearch;
        }).toList();

        if (blogs.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 24),
                Container(
                  height: 400,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        color: Colors.white24,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No $category blogs yet.'
                            : 'No results for "$_searchQuery" in $category.',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final featuredBlog = blogs.first;
        final otherBlogs = blogs.skip(1).toList();

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 24),
              // Trending Section
              _buildTrendingSection(allBlogs),
              const SizedBox(height: 32),
              // Featured Post Header
              const Text(
                'Featured Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Featured Post
              _buildFeaturedPost(featuredBlog, category),
              const SizedBox(height: 32),
              // Home List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category == 'All' ? 'Latest News' : category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Feed List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: otherBlogs.length,
                itemBuilder: (context, index) {
                  return _buildHorizontalBlogCard(otherBlogs[index], category);
                },
              ),
              // See More Button / Loading Indicator
              Obx(() {
                if (blogController.isLoadMoreLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                }

                if (blogController.hasMore.value && _searchQuery.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 40, top: 12),
                    child: GestureDetector(
                      onTap: () => blogController.fetchBlogsByCategory(
                        category,
                        isLoadMore: true,
                      ),
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.borderColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'See More Articles',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox(height: 48);
              }),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: AppColors.primaryColor,
          decoration: InputDecoration(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.primaryColor,
              size: 24,
            ),
            hintText: 'Search exclusive articles...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 15,
            ),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedPost(BlogModel blog, String category) {
    final hasImage = blog.imageUrl.isNotEmpty;
    final String heroTag = 'home_${category}_blog_${blog.id}';
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.blogDetail,
        arguments: {'blogId': blog.id, 'heroTag': heroTag},
      ),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(blog.imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.35),
                    BlendMode.darken,
                  ),
                )
              : null,
          gradient: hasImage
              ? null
              : LinearGradient(
                  colors: [
                    AppColors.secondaryColor.withOpacity(0.8),
                    AppColors.primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Hero for image
            if (hasImage)
              Hero(
                tag: 'home_${category}_blog_${blog.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    image: DecorationImage(
                      image: NetworkImage(blog.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            // Premium Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      blog.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    blog.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(blog.publishedDate),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Read More',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBlogCard(BlogModel blog, String category) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.blogDetail,
        arguments: {
          'blogId': blog.id,
          'heroTag': 'home_${category}_blog_${blog.id}',
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Side Image
            Hero(
              tag: 'home_${category}_blog_${blog.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: blog.imageUrl.isNotEmpty
                    ? Image.network(
                        blog.imageUrl,
                        height: 90,
                        width: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 90,
                          width: 90,
                          color: AppColors.cardBg,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white24,
                          ),
                        ),
                      )
                    : Container(
                        height: 90,
                        width: 90,
                        color: AppColors.cardBg,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          blog.category,
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white30,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white38,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(blog.publishedDate),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(List<BlogModel> blogs) {
    final trendingBlogs = blogs.where((b) => b.isFeatured).toList();
    if (trendingBlogs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: AppColors.primaryColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Trending',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trendingBlogs.length,
            itemBuilder: (context, index) {
              final blog = trendingBlogs[index];
              return GestureDetector(
                onTap: () => Get.toNamed(
                  AppRoutes.blogDetail,
                  arguments: {
                    'blogId': blog.id,
                    'heroTag': 'trending_blog_${blog.id}',
                  },
                ),
                child: Hero(
                  tag: 'trending_blog_${blog.id}',
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: blog.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(blog.imageUrl),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.2),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                      color: AppColors.cardBg,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blog.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => blogController.fetchBlogs(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                foregroundColor: AppColors.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.primaryColor),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
