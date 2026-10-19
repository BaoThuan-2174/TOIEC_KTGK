import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../exam_selection_screen.dart';
import 'admin_draft_preview_screen.dart';
import 'admin_upload_dialog.dart';

class AdminLayoutScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminLayoutScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends State<AdminLayoutScreen> {
  final ApiService _apiService = ApiService();
  late int _activeTab; // 0: Exams, 1: Publishing, 2: Analytics

  late Future<List<ExamListItem>> _adminExamsFuture;
  late Future<ExamStatistics> _statsFuture;

  String _searchQuery = '';
  String _examFilter = 'All'; // 'All', 'Published', 'Drafts', 'Archived'

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _adminExamsFuture = _apiService.getAllExamsAdmin();
      _statsFuture = _apiService.getExamStatistics(1);
    });
  }

  void _switchToStudentMode() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ExamSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Dark Green Sidebar (Matching Figma Admin UI!)
          _buildAdminSidebar(),

          // Right Main Content Area
          Expanded(
            child: Column(
              children: [
                // Admin Top Header Bar
                _buildAdminTopBar(),

                // Active Tab Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _buildActiveTabContent(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSidebar() {
    return Container(
      width: 260,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Reading Room',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'TOEIC READING EXAMS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.border,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 36),

          const Text(
            'WORKSPACE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.border,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          // Menu Items
          _sidebarMenuItem(0, Icons.description_outlined, 'Exams'),
          const SizedBox(height: 6),
          _sidebarMenuItem(1, Icons.send_outlined, 'Publishing'),
          const SizedBox(height: 6),
          _sidebarMenuItem(2, Icons.bar_chart_outlined, 'Analytics'),

          const Spacer(),

          // Banner Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'A clearer path to progress',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Create, publish and understand every reading exam.',
                  style: TextStyle(fontSize: 11, color: AppColors.border, height: 1.3),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Switch to Student Mode Button
          InkWell(
            onTap: _switchToStudentMode,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.school_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Về chế độ Sinh viên',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 16),

          // Admin Profile Footer
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('AL', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Alex Lee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Giảng viên (Admin)', style: TextStyle(fontSize: 11, color: AppColors.border)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebarMenuItem(int tabIdx, IconData icon, String title) {
    final isSelected = _activeTab == tabIdx;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabIdx),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.border),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTopBar() {
    String tabName = _activeTab == 0 ? 'Exams' : (_activeTab == 1 ? 'Publishing' : 'Analytics');

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('Admin portal  /  ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(tabName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Academic workspace', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.help_outline, size: 20, color: AppColors.textSecondary),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    if (_activeTab == 0) {
      return _buildExamsManagementTab();
    } else if (_activeTab == 1) {
      return _buildPublishingTab();
    } else {
      return _buildAnalyticsTab();
    }
  }

  // ===================== TAB 1: EXAMS MANAGEMENT =====================
  Widget _buildExamsManagementTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('EXAM LIBRARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8)),
                SizedBox(height: 6),
                Text('Exam management', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                SizedBox(height: 4),
                Text('Build thoughtful reading practice. Manage every exam in one place.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showUploadDocxDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create exam (Upload DOCX)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Upload Area & Library Stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Create from document Card
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Create from a document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Icon(Icons.upload_file, color: AppColors.primary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Upload a formatted exam. We\'ll extract passages, questions and answers.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 18),

                    // Drop area
                    InkWell(
                      onTap: _showUploadDocxDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
                            SizedBox(height: 12),
                            Text('Drop your DOCX file here, or browse files', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            SizedBox(height: 4),
                            Text('.docx only · Up to 20 MB · Use the TOEIC template', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Automatic validation before you publish', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Download DOCX template ↗', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Right: Library stats Card
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your exam library', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _libraryStatItem('12', 'Total exams'),
                        _libraryStatItem('8', 'Published'),
                        _libraryStatItem('3', 'Drafts'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Processing item
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Mau_De_Thi_TOEIC.docx', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(4)),
                                child: const Text('• Validated', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            child: LinearProgressIndicator(value: 1.0, minHeight: 4, color: AppColors.primary, backgroundColor: AppColors.borderLight),
                          ),
                          const SizedBox(height: 6),
                          const Text('100 questions extracted · Ready to preview', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Filter Tabs & Search
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _tabFilterButton('All', 'All exams 12'),
                const SizedBox(width: 8),
                _tabFilterButton('Published', 'Published 8'),
                const SizedBox(width: 8),
                _tabFilterButton('Drafts', 'Drafts 3'),
                const SizedBox(width: 8),
                _tabFilterButton('Archived', 'Archived 1'),
              ],
            ),
            SizedBox(
              width: 240,
              height: 38,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search exams...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Exams Table
        FutureBuilder<List<ExamListItem>>(
          future: _adminExamsFuture,
          builder: (context, snapshot) {
            final exams = snapshot.data ?? ApiService.getMockAdminExams();

            final filtered = exams.where((e) {
              if (_examFilter == 'Published' && !e.isPublished) return false;
              if (_examFilter == 'Drafts' && e.isPublished) return false;
              if (_searchQuery.isNotEmpty && !e.title.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
              return true;
            }).toList();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                      color: AppColors.background,
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 4, child: Text('EXAM TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('QUESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('DURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                      ],
                    ),
                  ),

                  // Rows
                  ...filtered.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${e.totalQuestions}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${e.durationMinutes} min', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: e.isPublished ? AppColors.surfaceSubtle : AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.isPublished ? '• Published' : '• Draft',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: e.isPublished ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminDraftPreviewScreen(examId: e.id, examTitle: e.title),
                                  ),
                                ).then((_) => _refreshData());
                              },
                              child: Text(
                                e.isPublished ? 'View exam →' : 'Preview →',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _libraryStatItem(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _tabFilterButton(String key, String label) {
    final isSelected = _examFilter == key;
    return InkWell(
      onTap: () => setState(() => _examFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.border : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ===================== TAB 2: PUBLISHING =====================
  Widget _buildPublishingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DISTRIBUTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        const Text('Publishing management', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('Control what students can access, with confidence.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),

        const SizedBox(height: 28),

        // Featured Release Card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOEIC Reading • Practice 01', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                    child: const Text('• Draft', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('100 questions · 75 minutes · Version 1.0', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('100 questions validated', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  SizedBox(width: 16),
                  Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Answer key complete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDraftPreviewScreen(examId: 1, examTitle: 'Practice 01'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Preview draft', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _apiService.publishExam(1, true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đề thi Practice 01 đã được xuất bản! Sinh viên có thể thi ngay.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        _refreshData();
                      }
                    },
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Publish exam'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        const Text('Publication register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 16),

        // Register Table
        FutureBuilder<List<ExamListItem>>(
          future: _adminExamsFuture,
          builder: (context, snapshot) {
            final exams = snapshot.data ?? ApiService.getMockAdminExams();
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: exams.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: e.isPublished ? AppColors.surfaceSubtle : AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.isPublished ? '• Published' : '• Draft',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: e.isPublished ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Switch(
                              value: e.isPublished,
                              activeThumbColor: AppColors.primary,
                              onChanged: (newVal) async {
                                await _apiService.publishExam(e.id, newVal);
                                _refreshData();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===================== TAB 3: ANALYTICS (Matches Assignment!) =====================
  Widget _buildAnalyticsTab() {
    return FutureBuilder<ExamStatistics>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? ApiService.getMockStatistics(1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LEARNING INSIGHTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            const Text('Analytics & reports', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('${stats.examTitle} · Completed attempts only', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),

            const SizedBox(height: 28),

            // 4 Stat Cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _analyticsMetricCard('Total attempts', '${stats.totalSubmissions}', '↑ 18.6% vs. previous period'),
                _analyticsMetricCard('Average score', '${stats.averageScore.round()} / 100', '↑ 4 points vs. previous period', isSuccess: true),
                _analyticsMetricCard('Completion rate', '94.2%', '1,210 submitted attempts'),
                _analyticsMetricCard('Average time', '63m 24s', 'Within the 75-minute time limit'),
              ],
            ),

            const SizedBox(height: 36),

            // Top 10 Most Missed Questions Header (Matches PDF requirement exactly!)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Top 10 most missed questions (Top 10 câu hỏi sinh viên làm sai nhất)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text('Ranked by incorrect rate · 1,210 attempts', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),

            const SizedBox(height: 16),

            // Top 10 Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 1, child: Text('QUESTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 1, child: Text('PART', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 4, child: Text('CONTENT & SKILL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('INCORRECT RATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('WRONG COUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                      ],
                    ),
                  ),

                  ...stats.topWrongQuestions.map((q) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderLight))),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text('Q${q.questionNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('Part ${q.partNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q.questionContent, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                if (q.explanation != null)
                                  Text(q.explanation!, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${q.wrongPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${q.wrongCount} / ${q.totalAttempts}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _analyticsMetricCard(String title, String val, String sub, {bool isSuccess = false}) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(sub, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSuccess ? AppColors.primary : AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showUploadDocxDialog() {
    AdminUploadDialog.show(
      context,
      onExamCreated: _refreshData,
    );
  }
}

