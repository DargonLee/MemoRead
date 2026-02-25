import { useEffect, useMemo, useState } from 'react';
import type { LucideIcon } from 'lucide-react';
import {
  AppWindowMac,
  Archive,
  ArrowUpRight,
  BookMarked,
  BookOpenText,
  CalendarClock,
  ChartNoAxesColumn,
  Clock3,
  Compass,
  Filter,
  Laptop,
  Link2,
  Search,
  SendHorizontal,
  Smartphone,
  Sparkles,
  Tag,
  Tags,
} from 'lucide-react';

type Surface = 'capture' | 'library' | 'insights';
type MemoStatus = 'queued' | 'inbox' | 'archived';
type SortMode = 'latest' | 'read' | 'source';
type CapturePanel = 'editor' | 'queue';

interface MemoItem {
  id: string;
  title: string;
  source: string;
  sourceIcon: string;
  tags: string[];
  note: string;
  url: string;
  capturedAt: string;
  readMinutes: number;
  status: MemoStatus;
}

interface SurfaceOption {
  id: Surface;
  label: string;
  detail: string;
  icon: LucideIcon;
}

const memoSamples: MemoItem[] = [
  {
    id: 'memo-1',
    title: 'AI Native 产品在 2026 年会出现哪些关键交互变化？',
    source: '微信公众号',
    sourceIcon: '💬',
    tags: ['AI', '产品策略', '交互趋势'],
    note: '回头重点看「自然语言入口 + 自动工作流」这段。',
    url: 'https://mp.weixin.qq.com/s/example-1',
    capturedAt: '02-25 08:23',
    readMinutes: 11,
    status: 'queued',
  },
  {
    id: 'memo-2',
    title: 'SwiftUI Observation 在跨平台状态管理里的最佳实践',
    source: '小红书',
    sourceIcon: '📕',
    tags: ['SwiftUI', '工程实践'],
    note: '用 @Observable 统一模型，iPhone 与 Mac 共用 ViewModel。',
    url: 'https://www.xiaohongshu.com/discovery/item/example-2',
    capturedAt: '02-24 18:54',
    readMinutes: 8,
    status: 'inbox',
  },
  {
    id: 'memo-3',
    title: '知识库检索体验设计：标签、语义搜索与时间维度',
    source: '知乎',
    sourceIcon: '🧠',
    tags: ['搜索体验', '信息架构', '知识管理'],
    note: '支持标签 + 全文 + 时间段是核心。',
    url: 'https://www.zhihu.com/question/example-3',
    capturedAt: '02-23 21:07',
    readMinutes: 15,
    status: 'queued',
  },
  {
    id: 'memo-4',
    title: '从输入到复盘：建立个人兴趣画像的统计框架',
    source: '微博',
    sourceIcon: '🌐',
    tags: ['数据分析', '兴趣画像'],
    note: '可按季度看主题热度变化。',
    url: 'https://weibo.com/example-4',
    capturedAt: '02-22 07:45',
    readMinutes: 6,
    status: 'inbox',
  },
  {
    id: 'memo-5',
    title: '创业团队如何用 Reader App 管理灵感与情报',
    source: '播客摘录',
    sourceIcon: '🎧',
    tags: ['创业', '团队协作'],
    note: '适合以后做共享空间功能。',
    url: 'https://podcasts.example.com/episode-5',
    capturedAt: '02-20 09:32',
    readMinutes: 22,
    status: 'archived',
  },
  {
    id: 'memo-6',
    title: 'macOS 端阅读器布局：三栏结构和快捷键策略',
    source: 'Twitter/X',
    sourceIcon: '🐦',
    tags: ['macOS', '效率工具'],
    note: 'command + k 全局搜索可极大提效。',
    url: 'https://x.com/example-6',
    capturedAt: '02-19 12:18',
    readMinutes: 9,
    status: 'inbox',
  },
];

const surfaces: SurfaceOption[] = [
  {
    id: 'capture',
    label: '通勤采集',
    detail: '手机快速记录与打标',
    icon: Smartphone,
  },
  {
    id: 'library',
    label: '办公深读',
    detail: 'Mac 检索与精读',
    icon: Laptop,
  },
  {
    id: 'insights',
    label: '兴趣统计',
    detail: '年度偏好趋势观察',
    icon: ChartNoAxesColumn,
  },
];

const monthlyCapture = [
  { month: '09月', count: 18 },
  { month: '10月', count: 24 },
  { month: '11月', count: 21 },
  { month: '12月', count: 28 },
  { month: '01月', count: 33 },
  { month: '02月', count: 37 },
];

const readingRhythm = [
  { period: '通勤早高峰', value: 74 },
  { period: '午休碎片', value: 42 },
  { period: '晚间复盘', value: 88 },
];

const captureSourceIcons: Record<string, string> = {
  微信公众号: '💬',
  小红书: '📕',
  知乎: '🧠',
  微博: '🌐',
  'Twitter/X': '🐦',
  网页: '🔖',
  播客摘录: '🎧',
};

const captureSourceOptions = Object.keys(captureSourceIcons);
const captureTagPool = ['AI', 'SwiftUI', '产品策略', '效率工具', '数据分析', '交互趋势', '知识管理', '创业'];
const baseYearlyCaptureTotal = monthlyCapture.reduce((sum, item) => sum + item.count, 0);

const statusFilters: Array<{ key: 'all' | MemoStatus; label: string }> = [
  { key: 'all', label: '全部' },
  { key: 'queued', label: '通勤队列' },
  { key: 'inbox', label: '待深读' },
  { key: 'archived', label: '已归档' },
];

const statusLabel: Record<MemoStatus, string> = {
  queued: '通勤队列',
  inbox: '待深读',
  archived: '已归档',
};

const sortOptions: Array<{ key: SortMode; label: string }> = [
  { key: 'latest', label: '最新采集优先' },
  { key: 'read', label: '预计阅读时长' },
  { key: 'source', label: '按来源分组' },
];

function memoCapturedTimestamp(capturedAt: string): number {
  const [datePart, timePart = '00:00'] = capturedAt.split(' ');
  const [month = '1', day = '1'] = datePart.split('-');
  const [hour = '0', minute = '0'] = timePart.split(':');
  const now = new Date();
  return new Date(now.getFullYear(), Number(month) - 1, Number(day), Number(hour), Number(minute)).getTime();
}

function formatCapturedAt(date: Date): string {
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hour = String(date.getHours()).padStart(2, '0');
  const minute = String(date.getMinutes()).padStart(2, '0');
  return `${month}-${day} ${hour}:${minute}`;
}

function normalizeUrl(url: string): string {
  const value = url.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  return `https://${value}`;
}

function statusClassName(status: MemoStatus): string {
  if (status === 'queued') {
    return 'status-pill status-queued';
  }

  if (status === 'inbox') {
    return 'status-pill status-inbox';
  }

  return 'status-pill status-archived';
}

function App() {
  const [memos, setMemos] = useState<MemoItem[]>(memoSamples);
  const [surface, setSurface] = useState<Surface>('capture');
  const [query, setQuery] = useState('');
  const [activeTag, setActiveTag] = useState<string>('全部');
  const [statusFilter, setStatusFilter] = useState<'all' | MemoStatus>('all');
  const [sourceFilter, setSourceFilter] = useState<string>('全部来源');
  const [sortMode, setSortMode] = useState<SortMode>('latest');
  const [selectedMemoId, setSelectedMemoId] = useState<string>(memoSamples[0].id);
  const [capturePanel, setCapturePanel] = useState<CapturePanel>('editor');
  const [captureSource, setCaptureSource] = useState<string>(captureSourceOptions[0]);
  const [captureTitle, setCaptureTitle] = useState('');
  const [captureUrl, setCaptureUrl] = useState('');
  const [captureNote, setCaptureNote] = useState('');
  const [captureTags, setCaptureTags] = useState<string[]>(['AI']);
  const [captureListQuery, setCaptureListQuery] = useState('');
  const [captureListStatus, setCaptureListStatus] = useState<'all' | MemoStatus>('all');
  const [captureListSelectedId, setCaptureListSelectedId] = useState<string>(memoSamples[0].id);
  const [captureFeedback, setCaptureFeedback] = useState('');

  const allTags = useMemo(() => ['全部', ...Array.from(new Set(memos.flatMap((memo) => memo.tags)))], [memos]);
  const topTags = useMemo(() => {
    const tagCounter = memos.reduce<Record<string, number>>((acc, memo) => {
      memo.tags.forEach((tag) => {
        acc[tag] = (acc[tag] ?? 0) + 1;
      });
      return acc;
    }, {});

    return Object.entries(tagCounter)
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }, [memos]);
  const sourceMix = useMemo(() => {
    const sourceCounter = memos.reduce<Record<string, number>>((acc, memo) => {
      acc[memo.source] = (acc[memo.source] ?? 0) + 1;
      return acc;
    }, {});

    return Object.entries(sourceCounter)
      .map(([name, count]) => ({ name, count }))
      .sort((a, b) => b.count - a.count);
  }, [memos]);
  const statusTotals = useMemo(() => {
    return memos.reduce<Record<MemoStatus, number>>(
      (acc, memo) => {
        acc[memo.status] += 1;
        return acc;
      },
      { queued: 0, inbox: 0, archived: 0 },
    );
  }, [memos]);
  const sourceFilters = useMemo(() => ['全部来源', ...sourceMix.map((source) => source.name)], [sourceMix]);
  const yearlyCaptureTotal = useMemo(
    () => baseYearlyCaptureTotal + Math.max(0, memos.length - memoSamples.length),
    [memos.length],
  );

  const filteredMemos = useMemo(() => {
    const queryLower = query.trim().toLowerCase();

    return memos
      .filter((memo) => {
        const matchesQuery =
          queryLower.length === 0 ||
          memo.title.toLowerCase().includes(queryLower) ||
          memo.note.toLowerCase().includes(queryLower) ||
          memo.source.toLowerCase().includes(queryLower) ||
          memo.tags.some((tag) => tag.toLowerCase().includes(queryLower));
        const matchesTag = activeTag === '全部' || memo.tags.includes(activeTag);
        const matchesStatus = statusFilter === 'all' || memo.status === statusFilter;
        const matchesSource = sourceFilter === '全部来源' || memo.source === sourceFilter;
        return matchesQuery && matchesTag && matchesStatus && matchesSource;
      })
      .sort((left, right) => {
        if (sortMode === 'read') {
          if (right.readMinutes !== left.readMinutes) {
            return right.readMinutes - left.readMinutes;
          }
          return memoCapturedTimestamp(right.capturedAt) - memoCapturedTimestamp(left.capturedAt);
        }

        if (sortMode === 'source') {
          const sourceCompare = left.source.localeCompare(right.source, 'zh-Hans-CN');
          if (sourceCompare !== 0) {
            return sourceCompare;
          }
        }

        return memoCapturedTimestamp(right.capturedAt) - memoCapturedTimestamp(left.capturedAt);
      });
  }, [activeTag, memos, query, sourceFilter, sortMode, statusFilter]);

  const appListMemos = useMemo(() => {
    const queryLower = captureListQuery.trim().toLowerCase();
    return memos
      .filter((memo) => captureListStatus === 'all' || memo.status === captureListStatus)
      .filter((memo) => {
        if (queryLower.length === 0) {
          return true;
        }

        return (
          memo.title.toLowerCase().includes(queryLower) ||
          memo.source.toLowerCase().includes(queryLower) ||
          memo.note.toLowerCase().includes(queryLower) ||
          memo.tags.some((tag) => tag.toLowerCase().includes(queryLower))
        );
      })
      .sort((left, right) => memoCapturedTimestamp(right.capturedAt) - memoCapturedTimestamp(left.capturedAt));
  }, [captureListQuery, captureListStatus, memos]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        setSurface('library');
        requestAnimationFrame(() => {
          const input = document.getElementById('memo-search-input');
          input?.focus();
        });
      }

      if (event.metaKey || event.ctrlKey || event.altKey) {
        return;
      }

      if (event.key === '1') {
        setSurface('capture');
      } else if (event.key === '2') {
        setSurface('library');
      } else if (event.key === '3') {
        setSurface('insights');
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, []);

  useEffect(() => {
    if (!captureFeedback) {
      return;
    }

    const timer = window.setTimeout(() => {
      setCaptureFeedback('');
    }, 1800);

    return () => window.clearTimeout(timer);
  }, [captureFeedback]);

  const toggleCaptureTag = (tag: string) => {
    setCaptureTags((prev) => {
      if (prev.includes(tag)) {
        return prev.filter((item) => item !== tag);
      }
      return [...prev, tag];
    });
  };

  const saveCapturedMemo = () => {
    const title = captureTitle.trim();
    const url = captureUrl.trim();
    if (title.length === 0 || url.length === 0) {
      setCaptureFeedback('请至少填写标题和链接');
      return;
    }

    const safeTags = captureTags.length > 0 ? captureTags : ['未分类'];
    const readMinutes = Math.min(30, Math.max(4, Math.round((title.length + captureNote.trim().length) / 16)));
    const newMemo: MemoItem = {
      id: `memo-${Date.now()}`,
      title,
      source: captureSource,
      sourceIcon: captureSourceIcons[captureSource] ?? '🔖',
      tags: safeTags,
      note: captureNote.trim() || '通勤采集，待到公司后补充精读备注。',
      url: normalizeUrl(url),
      capturedAt: formatCapturedAt(new Date()),
      readMinutes,
      status: 'queued',
    };

    setMemos((prev) => [newMemo, ...prev]);
    setSelectedMemoId(newMemo.id);
    setCaptureListSelectedId(newMemo.id);
    setCaptureListStatus('all');
    setCaptureListQuery('');
    setCaptureTitle('');
    setCaptureUrl('');
    setCaptureNote('');
    setCaptureTags((prev) => (prev.length === 0 ? ['AI'] : prev));
    setCapturePanel('queue');
    setCaptureFeedback('已加入通勤队列');
  };

  const clearCaptureDraft = () => {
    setCaptureTitle('');
    setCaptureUrl('');
    setCaptureNote('');
    setCaptureTags(['AI']);
    setCaptureFeedback('已清空草稿');
  };

  const updateMemoStatus = (memoId: string, nextStatus: MemoStatus, feedbackText: string) => {
    setMemos((prev) => prev.map((memo) => (memo.id === memoId ? { ...memo, status: nextStatus } : memo)));
    setCaptureFeedback(feedbackText);
  };

  const openMemoOnLibrary = (memoId: string) => {
    setSelectedMemoId(memoId);
    setSurface('library');
    setStatusFilter('all');
    setSourceFilter('全部来源');
    setActiveTag('全部');
    setQuery('');
  };

  const selectedMemo = filteredMemos.find((memo) => memo.id === selectedMemoId) ?? filteredMemos[0];
  const maxMonthlyCount = Math.max(...monthlyCapture.map((item) => item.count));
  const maxTagCount = Math.max(1, ...topTags.map((item) => item.count));
  const maxSourceCount = Math.max(1, ...sourceMix.map((item) => item.count));
  const capturePreview = memos.find((memo) => memo.status === 'queued') ?? memos[0];
  const avgReadMinutes = Math.round(
    memos.reduce((total, memo) => total + memo.readMinutes, 0) / Math.max(1, memos.length),
  );
  const focusScore = Math.round(readingRhythm.reduce((total, item) => total + item.value, 0) / readingRhythm.length);
  const activeFilterLabels = [
    statusFilter !== 'all' ? statusLabel[statusFilter] : null,
    activeTag !== '全部' ? activeTag : null,
    sourceFilter !== '全部来源' ? sourceFilter : null,
    query.trim() ? `关键词：${query.trim()}` : null,
  ].filter((value): value is string => Boolean(value));
  const strongestTag = topTags[0]?.name ?? '内容分类';
  const strongestSource = sourceMix[0]?.name ?? '来源渠道';
  const capturePreviewTitle = captureTitle.trim().length > 0 ? captureTitle.trim() : capturePreview?.title ?? '';
  const capturePreviewUrl = captureUrl.trim().length > 0 ? normalizeUrl(captureUrl) : capturePreview?.url ?? '';
  const capturePreviewSource = captureSource || capturePreview?.source || '网页';
  const capturePreviewTags = captureTags.length > 0 ? captureTags : ['未分类'];
  const selectedAppListMemo = appListMemos.find((memo) => memo.id === captureListSelectedId) ?? appListMemos[0];
  const nextStatusAction =
    selectedAppListMemo?.status === 'queued'
      ? { status: 'inbox' as MemoStatus, label: '转入待深读', feedback: '已转入待深读' }
      : selectedAppListMemo?.status === 'inbox'
        ? { status: 'archived' as MemoStatus, label: '归档', feedback: '已归档' }
        : { status: 'queued' as MemoStatus, label: '重新入队', feedback: '已重新加入队列' };

  return (
    <div className="min-h-screen px-4 py-6 md:px-8 md:py-10">
      <div className="design-shell mx-auto">
        <span className="ambient-orb ambient-orb-a" />
        <span className="ambient-orb ambient-orb-b" />

        <header className="control-panel">
          <p className="eyebrow">MemoRead / Product UI Exploration</p>
          <h1 className="display-title">通勤剪藏，到工位深读</h1>
          <p className="intro-copy">
            这版界面聚焦你的真实流程：路上用手机快速摘录，进公司后在 Mac 上进行搜索、归档与复盘，持续形成你的兴趣轨迹。
          </p>
          <p className="shortcut-hint">快捷键：1 通勤采集 · 2 办公深读 · 3 兴趣统计 · ⌘/Ctrl + K 全局搜索</p>

          <div className="surface-switch">
            {surfaces.map((item) => {
              const Icon = item.icon;
              const active = surface === item.id;

              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setSurface(item.id)}
                  className={`surface-option ${active ? 'is-active' : ''}`}
                >
                  <div className="flex items-start gap-3">
                    <Icon className="mt-0.5 h-4 w-4" />
                    <div className="text-left">
                      <p className="font-medium">{item.label}</p>
                      <p className="text-xs opacity-80">{item.detail}</p>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          <div className="kpi-grid">
            <article className="kpi-tile">
              <p className="kpi-label">年度剪藏</p>
              <p className="kpi-value">{yearlyCaptureTotal}</p>
            </article>
            <article className="kpi-tile">
              <p className="kpi-label">待深读</p>
              <p className="kpi-value">{statusTotals.inbox}</p>
            </article>
            <article className="kpi-tile">
              <p className="kpi-label">通勤队列</p>
              <p className="kpi-value">{statusTotals.queued}</p>
            </article>
            <article className="kpi-tile">
              <p className="kpi-label">主题标签</p>
              <p className="kpi-value">{allTags.length - 1}</p>
            </article>
          </div>
        </header>

        <main className="mt-6 space-y-6">
          {surface === 'capture' && (
            <section className="scene-card">
              <div className="capture-mode-switch">
                <button
                  type="button"
                  onClick={() => setCapturePanel('editor')}
                  className={`capture-mode-btn ${capturePanel === 'editor' ? 'is-active' : ''}`}
                >
                  快速采集
                </button>
                <button
                  type="button"
                  onClick={() => setCapturePanel('queue')}
                  className={`capture-mode-btn ${capturePanel === 'queue' ? 'is-active' : ''}`}
                >
                  App 列表
                  <span className="capture-count">{memos.length}</span>
                </button>
                {captureFeedback && <p className="capture-feedback">{captureFeedback}</p>}
              </div>

              {capturePanel === 'editor' && (
                <div className="grid gap-6 lg:grid-cols-[340px_minmax(0,1fr)]">
                  <article className="phone-shell">
                    <div className="phone-notch" />
                    <div className="phone-screen">
                      <div className="phone-status-bar">
                        <span className="text-xs font-semibold">9:41</span>
                        <span className="text-xs text-slate-500">5G</span>
                      </div>

                      <div className="p-4">
                        <div className="mb-4 flex items-center justify-between">
                          <button type="button" className="text-sm text-slate-500" onClick={clearCaptureDraft}>
                            清空
                          </button>
                          <p className="text-sm font-semibold">保存到 MemoRead</p>
                          <button type="button" className="text-sm font-semibold text-[var(--teal)]" onClick={saveCapturedMemo}>
                            入队
                          </button>
                        </div>

                        <div className="capture-form-block">
                          <label className="capture-field">
                            <span>来源</span>
                            <select value={captureSource} onChange={(event) => setCaptureSource(event.target.value)} className="capture-select">
                              {captureSourceOptions.map((source) => (
                                <option key={source} value={source}>
                                  {source}
                                </option>
                              ))}
                            </select>
                          </label>
                          <label className="capture-field">
                            <span>标题</span>
                            <textarea
                              value={captureTitle}
                              onChange={(event) => setCaptureTitle(event.target.value)}
                              className="capture-input"
                              rows={2}
                              placeholder="例如：SwiftUI 在跨端状态管理里的最佳实践"
                            />
                          </label>
                          <label className="capture-field">
                            <span>链接</span>
                            <input
                              value={captureUrl}
                              onChange={(event) => setCaptureUrl(event.target.value)}
                              className="capture-input"
                              placeholder="粘贴文章或帖子的 URL"
                            />
                          </label>
                        </div>

                        <div className="mt-4">
                          <p className="mb-2 text-xs uppercase tracking-wide text-slate-500">快速标签</p>
                          <div className="flex flex-wrap gap-2">
                            {captureTagPool.map((tag) => (
                              <button
                                key={tag}
                                type="button"
                                onClick={() => toggleCaptureTag(tag)}
                                className={`capture-tag-btn ${captureTags.includes(tag) ? 'is-active' : ''}`}
                              >
                                {tag}
                              </button>
                            ))}
                          </div>
                        </div>

                        <label className="capture-field mt-4">
                          <span>通勤备注（可选）</span>
                          <textarea
                            value={captureNote}
                            onChange={(event) => setCaptureNote(event.target.value)}
                            className="capture-input"
                            rows={2}
                            placeholder="先记一个阅读重点，晚点在 Mac 上展开。"
                          />
                        </label>

                        <div className="mt-4 rounded-2xl border border-[var(--line)] bg-[rgba(255,255,255,0.65)] p-3">
                          <div className="mb-2 flex items-center gap-2 text-sm text-slate-600">
                            <Sparkles className="h-4 w-4 text-[var(--clay)]" />
                            即时预览
                          </div>
                          <p className="text-[11px] text-slate-500">已识别来源 · {capturePreviewSource}</p>
                          <p className="mt-1 text-sm font-semibold leading-snug">
                            {capturePreviewTitle || '输入标题后，这里会展示采集预览'}
                          </p>
                          <div className="mt-2 flex items-center gap-2 text-xs text-slate-500">
                            <Link2 className="h-3.5 w-3.5" />
                            <span className="truncate">{capturePreviewUrl || '等待输入链接'}</span>
                          </div>
                          <div className="mt-2 flex flex-wrap gap-1.5">
                            {capturePreviewTags.map((tag) => (
                              <span key={tag} className="chip-tag text-[11px]">
                                {tag}
                              </span>
                            ))}
                          </div>
                        </div>

                        <div className="mt-4 flex items-center gap-2 rounded-xl bg-[rgba(63,110,103,0.14)] px-3 py-2 text-xs text-[var(--teal)]">
                          <Clock3 className="h-3.5 w-3.5" />
                          保存后会进入 App 列表，到公司可一键进入办公深读
                        </div>
                      </div>
                    </div>
                  </article>

                  <article className="grid gap-4 content-start">
                    {[
                      {
                        icon: SendHorizontal,
                        title: '路上看到内容，2 秒进箱',
                        description:
                          '直接粘贴链接并打标签，不再先发企业微信。你在通勤时的注意力只花在内容判断上。',
                      },
                      {
                        icon: CalendarClock,
                        title: '自动补齐时间与场景',
                        description:
                          '每条内容都写入采集时间、来源与状态，后续在 Mac 端可以按来源和阅读优先级排序。',
                      },
                      {
                        icon: Compass,
                        title: '到公司后无缝切换深读',
                        description:
                          '在 App 列表里管理记录状态，并一键跳转到办公深读工作台。',
                      },
                    ].map((step, index) => {
                      const Icon = step.icon;

                      return (
                        <div
                          key={step.title}
                          className="flow-step"
                          style={{ animationDelay: `${index * 120}ms` }}
                        >
                          <div className="mb-2 flex items-center gap-2">
                            <Icon className="h-4 w-4 text-[var(--clay)]" />
                            <h3 className="text-lg font-semibold">{step.title}</h3>
                          </div>
                          <p className="text-sm leading-relaxed text-slate-600">{step.description}</p>
                        </div>
                      );
                    })}

                    <div className="sync-strip">
                      <p className="kpi-label">跨端接力状态</p>
                      <div className="sync-track">
                        <div className="sync-node">
                          <p className="sync-title">iPhone 采集</p>
                          <p className="sync-copy">通勤中快速记录，默认进入队列</p>
                        </div>
                        <div className="sync-arrow">→</div>
                        <div className="sync-node">
                          <p className="sync-title">iCloud 同步</p>
                          <p className="sync-copy">平均延迟 3.2 秒，自动推送到桌面端</p>
                        </div>
                        <div className="sync-arrow">→</div>
                        <div className="sync-node">
                          <p className="sync-title">Mac 深读</p>
                          <p className="sync-copy">选择条目后进入三栏深读与归档</p>
                        </div>
                      </div>
                    </div>
                  </article>
                </div>
              )}

              {capturePanel === 'queue' && (
                <div className="grid gap-6 lg:grid-cols-[340px_minmax(0,1fr)]">
                  <article className="phone-shell">
                    <div className="phone-notch" />
                    <div className="phone-screen">
                      <div className="phone-status-bar">
                        <span className="text-xs font-semibold">9:41</span>
                        <span className="text-xs text-slate-500">MemoRead</span>
                      </div>

                      <div className="p-4 pt-2">
                        <div className="app-list-head">
                          <p className="text-sm font-semibold">App 列表</p>
                          <span className="text-xs text-slate-500">{appListMemos.length} 条</span>
                        </div>

                        <div className="desktop-search phone-search">
                          <Search className="h-4 w-4 text-slate-400" />
                          <input
                            value={captureListQuery}
                            onChange={(event) => setCaptureListQuery(event.target.value)}
                            placeholder="搜索标题、来源、标签"
                          />
                        </div>

                        <div className="phone-filter-row">
                          {statusFilters.map((statusItem) => (
                            <button
                              key={statusItem.key}
                              type="button"
                              onClick={() => setCaptureListStatus(statusItem.key)}
                              className={`phone-filter-btn ${captureListStatus === statusItem.key ? 'is-active' : ''}`}
                            >
                              {statusItem.label}
                            </button>
                          ))}
                        </div>

                        <div className="phone-list-scroll">
                          {appListMemos.length === 0 && (
                            <div className="empty-card">
                              <p className="text-sm font-semibold">没有匹配内容</p>
                              <p className="mt-1 text-xs text-slate-500">调整搜索词或状态筛选后再试。</p>
                            </div>
                          )}

                          {appListMemos.map((memo) => (
                            <button
                              key={memo.id}
                              type="button"
                              onClick={() => setCaptureListSelectedId(memo.id)}
                              className={`phone-list-item ${selectedAppListMemo?.id === memo.id ? 'is-selected' : ''}`}
                            >
                              <div className="mb-1 flex items-start justify-between gap-2">
                                <p className="line-clamp-2 text-left text-sm font-semibold">{memo.title}</p>
                                <span>{memo.sourceIcon}</span>
                              </div>
                              <div className="text-left text-[11px] text-slate-500">
                                {memo.source} · {memo.capturedAt}
                              </div>
                              <div className="mt-2 flex items-center justify-between">
                                <span className={statusClassName(memo.status)}>{statusLabel[memo.status]}</span>
                                <span className="text-[11px] text-slate-500">{memo.readMinutes} 分钟</span>
                              </div>
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>
                  </article>

                  <article className="app-list-side">
                    {!selectedAppListMemo && (
                      <div className="empty-card">
                        <p className="text-base font-semibold">请选择一条记录</p>
                        <p className="mt-1 text-sm text-slate-500">右侧会展示内容详情和状态操作。</p>
                      </div>
                    )}

                    {selectedAppListMemo && (
                      <article className="detail-card h-auto">
                        <div className="mb-4 flex items-start justify-between gap-4">
                          <div>
                            <p className="mb-1 text-xs text-slate-500">{selectedAppListMemo.source}</p>
                            <h3 className="text-xl font-semibold leading-tight">{selectedAppListMemo.title}</h3>
                          </div>
                          <span className="text-2xl">{selectedAppListMemo.sourceIcon}</span>
                        </div>

                        <div className="mb-3 flex flex-wrap gap-2">
                          {selectedAppListMemo.tags.map((tag) => (
                            <span key={tag} className="chip-tag">
                              {tag}
                            </span>
                          ))}
                        </div>

                        <p className="text-sm leading-relaxed text-slate-700">{selectedAppListMemo.note}</p>

                        <div className="mt-4 flex flex-wrap gap-2">
                          <button
                            type="button"
                            className="action-btn ghost"
                            onClick={() =>
                              updateMemoStatus(selectedAppListMemo.id, nextStatusAction.status, nextStatusAction.feedback)
                            }
                          >
                            {nextStatusAction.label}
                          </button>
                          <button type="button" className="action-btn" onClick={() => openMemoOnLibrary(selectedAppListMemo.id)}>
                            <ArrowUpRight className="h-4 w-4" />
                            去办公深读
                          </button>
                        </div>

                        <div className="mt-4 rounded-xl bg-[rgba(63,110,103,0.12)] p-3 text-sm text-[var(--teal)]">
                          采集于 {selectedAppListMemo.capturedAt} · 预计阅读 {selectedAppListMemo.readMinutes} 分钟
                        </div>
                      </article>
                    )}

                    <div className="sync-strip">
                      <p className="kpi-label">App 列表流转</p>
                      <div className="sync-track">
                        <div className="sync-node">
                          <p className="sync-title">通勤采集</p>
                          <p className="sync-copy">新内容进入通勤队列</p>
                        </div>
                        <div className="sync-arrow">→</div>
                        <div className="sync-node">
                          <p className="sync-title">待深读</p>
                          <p className="sync-copy">在公司安排深度处理</p>
                        </div>
                        <div className="sync-arrow">→</div>
                        <div className="sync-node">
                          <p className="sync-title">归档复盘</p>
                          <p className="sync-copy">进入年度兴趣统计分析</p>
                        </div>
                      </div>
                    </div>
                  </article>
                </div>
              )}
            </section>
          )}

          {surface === 'library' && (
            <section className="scene-card p-0">
              <div className="desktop-shell">
                <div className="desktop-topbar">
                  <div className="window-dots">
                    <span className="dot dot-red" />
                    <span className="dot dot-amber" />
                    <span className="dot dot-green" />
                  </div>
                  <div className="desktop-search">
                    <Search className="h-4 w-4 text-slate-400" />
                    <input
                      id="memo-search-input"
                      value={query}
                      onChange={(event) => setQuery(event.target.value)}
                      placeholder="搜索标题、备注、标签或来源"
                    />
                  </div>
                  <div className="desktop-topbar-controls">
                    <label className="select-wrap">
                      <span>来源</span>
                      <select
                        value={sourceFilter}
                        onChange={(event) => setSourceFilter(event.target.value)}
                        className="desk-select"
                      >
                        {sourceFilters.map((sourceName) => (
                          <option key={sourceName} value={sourceName}>
                            {sourceName}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label className="select-wrap">
                      <span>排序</span>
                      <select
                        value={sortMode}
                        onChange={(event) => setSortMode(event.target.value as SortMode)}
                        className="desk-select"
                      >
                        {sortOptions.map((option) => (
                          <option key={option.key} value={option.key}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                    </label>
                    <button type="button" className="desk-filter-btn">
                      <Filter className="h-4 w-4" />
                      筛选器
                    </button>
                  </div>
                </div>

                <div className="desktop-content">
                  <aside className="desktop-sidebar">
                    <p className="side-title">工作区</p>
                    <div className="space-y-2">
                      {statusFilters.map((statusItem) => {
                        const active = statusFilter === statusItem.key;
                        return (
                          <button
                            key={statusItem.key}
                            type="button"
                            onClick={() => setStatusFilter(statusItem.key)}
                            className={`side-link ${active ? 'is-active' : ''}`}
                          >
                            {statusItem.key === 'archived' ? (
                              <Archive className="h-4 w-4" />
                            ) : (
                              <BookOpenText className="h-4 w-4" />
                            )}
                            <span>{statusItem.label}</span>
                          </button>
                        );
                      })}
                    </div>

                    <p className="side-title mt-6">兴趣标签</p>
                    <div className="flex flex-wrap gap-2">
                      {allTags.map((tag) => (
                        <button
                          key={tag}
                          type="button"
                          onClick={() => setActiveTag(tag)}
                          className={`tag-filter ${activeTag === tag ? 'is-active' : ''}`}
                        >
                          {tag}
                        </button>
                      ))}
                    </div>
                  </aside>

                  <div className="desktop-list">
                    <div className="list-header">
                      <h3>内容列表</h3>
                      <div className="list-meta">
                        <p>{filteredMemos.length} 条结果</p>
                        {activeFilterLabels.length > 0 && (
                          <div className="active-filter-list">
                            {activeFilterLabels.map((label) => (
                              <span key={label} className="active-filter-chip">
                                {label}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="memo-scroll">
                      {filteredMemos.length === 0 && (
                        <div className="empty-card">
                          <p className="text-base font-semibold">没有匹配内容</p>
                          <p className="mt-1 text-sm text-slate-500">调整关键词、标签或状态后再试。</p>
                        </div>
                      )}

                      {filteredMemos.map((memo) => (
                        <button
                          key={memo.id}
                          type="button"
                          onClick={() => setSelectedMemoId(memo.id)}
                          className={`memo-item ${selectedMemo?.id === memo.id ? 'is-selected' : ''}`}
                        >
                          <div className="mb-2 flex items-start justify-between gap-3">
                            <p className="line-clamp-2 text-left text-sm font-semibold leading-snug">{memo.title}</p>
                            <span className="text-lg">{memo.sourceIcon}</span>
                          </div>

                          <div className="mb-2 flex items-center gap-2 text-xs text-slate-500">
                            <Tag className="h-3.5 w-3.5" />
                            <span>{memo.source}</span>
                            <span>·</span>
                            <span>{memo.capturedAt}</span>
                          </div>

                          <div className="flex flex-wrap gap-1.5">
                            {memo.tags.slice(0, 3).map((tag) => (
                              <span key={tag} className="chip-tag text-[11px]">
                                {tag}
                              </span>
                            ))}
                          </div>

                          <div className="mt-3">
                            <span className={statusClassName(memo.status)}>{statusLabel[memo.status]}</span>
                          </div>
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="desktop-detail">
                    {!selectedMemo && (
                      <div className="empty-card h-full">
                        <p className="text-base font-semibold">请选择一条内容</p>
                        <p className="mt-1 text-sm text-slate-500">右侧将显示可编辑备注、原文链接和归档操作。</p>
                      </div>
                    )}

                    {selectedMemo && (
                      <article className="detail-card">
                        <div className="mb-4 flex items-start justify-between gap-4">
                          <div>
                            <p className="mb-2 text-sm text-slate-500">{selectedMemo.source}</p>
                            <h3 className="text-2xl font-semibold leading-tight">{selectedMemo.title}</h3>
                          </div>
                          <span className="text-2xl">{selectedMemo.sourceIcon}</span>
                        </div>

                        <div className="mb-4 flex flex-wrap gap-2">
                          {selectedMemo.tags.map((tag) => (
                            <span key={tag} className="chip-tag">
                              {tag}
                            </span>
                          ))}
                        </div>

                        <div className="mb-4 rounded-2xl border border-[var(--line)] bg-[rgba(255,255,255,0.7)] p-4">
                          <p className="mb-2 text-xs uppercase tracking-wide text-slate-500">我的备注</p>
                          <p className="text-sm leading-relaxed text-slate-700">{selectedMemo.note}</p>
                        </div>

                        <div className="mb-6 flex items-center justify-between rounded-xl bg-[rgba(63,110,103,0.12)] p-3 text-sm">
                          <div className="flex items-center gap-2 text-[var(--teal)]">
                            <Clock3 className="h-4 w-4" />
                            预计阅读 {selectedMemo.readMinutes} 分钟
                          </div>
                          <span className="text-slate-500">采集于 {selectedMemo.capturedAt}</span>
                        </div>

                        <div className="flex flex-wrap gap-3">
                          <a className="action-btn" href={selectedMemo.url} target="_blank" rel="noreferrer">
                            <Link2 className="h-4 w-4" />
                            打开原文
                          </a>
                          <button type="button" className="action-btn ghost" onClick={() => setSurface('insights')}>
                            <ArrowUpRight className="h-4 w-4" />
                            查看趋势
                          </button>
                        </div>
                      </article>
                    )}
                  </div>
                </div>
              </div>
            </section>
          )}

          {surface === 'insights' && (
            <section className="scene-card">
              <div className="grid gap-4 md:grid-cols-5">
                <article className="glass-card rounded-2xl p-4">
                  <p className="kpi-label">总剪藏</p>
                  <p className="kpi-value">{memos.length}</p>
                </article>
                <article className="glass-card rounded-2xl p-4">
                  <p className="kpi-label">待深读</p>
                  <p className="kpi-value">{statusTotals.inbox}</p>
                </article>
                <article className="glass-card rounded-2xl p-4">
                  <p className="kpi-label">已归档</p>
                  <p className="kpi-value">{statusTotals.archived}</p>
                </article>
                <article className="glass-card rounded-2xl p-4">
                  <p className="kpi-label">兴趣维度</p>
                  <p className="kpi-value">{topTags.length}</p>
                </article>
                <article className="glass-card rounded-2xl p-4">
                  <p className="kpi-label">平均阅读</p>
                  <p className="kpi-value">{avgReadMinutes}m</p>
                </article>
              </div>

              <div className="mt-4 grid gap-4 xl:grid-cols-[minmax(0,1.25fr)_minmax(0,1fr)]">
                <article className="glass-card rounded-2xl p-5">
                  <div className="mb-4 flex items-center justify-between">
                    <h3 className="text-lg font-semibold">月度采集趋势</h3>
                    <span className="text-xs text-slate-500">最近 6 个月</span>
                  </div>
                  <div className="trend-bars">
                    {monthlyCapture.map((item) => (
                      <div key={item.month} className="trend-item">
                        <span className="trend-value">{item.count}</span>
                        <div
                          className="trend-bar"
                          style={{ height: `${(item.count / maxMonthlyCount) * 170}px` }}
                        />
                        <span className="trend-label">{item.month}</span>
                      </div>
                    ))}
                  </div>
                </article>

                <article className="glass-card rounded-2xl p-5">
                  <div className="mb-4 flex items-center justify-between">
                    <h3 className="text-lg font-semibold">阅读节奏</h3>
                    <CalendarClock className="h-4 w-4 text-[var(--teal)]" />
                  </div>
                  <div className="space-y-4">
                    {readingRhythm.map((item) => (
                      <div key={item.period}>
                        <div className="mb-1 flex items-center justify-between text-sm">
                          <span>{item.period}</span>
                          <span className="text-slate-500">{item.value}%</span>
                        </div>
                        <div className="h-2 rounded-full bg-[rgba(63,110,103,0.15)]">
                          <div className="h-2 rounded-full bg-[var(--teal)]" style={{ width: `${item.value}%` }} />
                        </div>
                      </div>
                    ))}
                  </div>
                </article>
              </div>

              <div className="mt-4 grid gap-4 lg:grid-cols-2">
                <article className="glass-card rounded-2xl p-5">
                  <div className="mb-4 flex items-center justify-between">
                    <h3 className="text-lg font-semibold">主题热度</h3>
                    <Tags className="h-4 w-4 text-[var(--clay)]" />
                  </div>
                  <div className="space-y-3">
                    {topTags.map((item) => (
                      <div key={item.name}>
                        <div className="mb-1 flex items-center justify-between text-sm">
                          <span>{item.name}</span>
                          <span className="text-slate-500">{item.count}</span>
                        </div>
                        <div className="h-2 rounded-full bg-[rgba(208,114,78,0.17)]">
                          <div
                            className="h-2 rounded-full bg-[var(--clay)]"
                            style={{ width: `${(item.count / maxTagCount) * 100}%` }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </article>

                <article className="glass-card rounded-2xl p-5">
                  <div className="mb-4 flex items-center justify-between">
                    <h3 className="text-lg font-semibold">来源分布</h3>
                    <BookOpenText className="h-4 w-4 text-[var(--teal)]" />
                  </div>
                  <div className="space-y-3">
                    {sourceMix.map((item) => (
                      <div key={item.name}>
                        <div className="mb-1 flex items-center justify-between text-sm">
                          <span>{item.name}</span>
                          <span className="text-slate-500">{item.count}</span>
                        </div>
                        <div className="h-2 rounded-full bg-[rgba(63,110,103,0.14)]">
                          <div
                            className="h-2 rounded-full bg-gradient-to-r from-[var(--teal)] to-[var(--teal-soft)]"
                            style={{ width: `${(item.count / maxSourceCount) * 100}%` }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </article>
              </div>

              <article className="insight-narrative mt-4">
                <div>
                  <p className="kpi-label">兴趣雷达结论</p>
                  <h3 className="text-xl font-semibold">你当前的关注主轴是「{strongestTag}」</h3>
                  <p className="mt-2 text-sm leading-relaxed text-slate-600">
                    最近内容主要来自 {strongestSource}，平均阅读时长 {avgReadMinutes} 分钟，专注分值 {focusScore}
                    /100。建议在 Mac 端建立一个「{strongestTag}」智能分组，优先清空待深读队列。
                  </p>
                </div>
                <button type="button" className="action-btn" onClick={() => setSurface('library')}>
                  <ArrowUpRight className="h-4 w-4" />
                  回到深读工作台
                </button>
              </article>
            </section>
          )}

          <section className="scene-card blueprint-card">
            <div className="mb-4 flex flex-wrap items-start justify-between gap-4">
              <div>
                <p className="eyebrow">SwiftUI 实施蓝图</p>
                <h2 className="text-2xl font-semibold">一份代码同时跑 iPhone 与 Mac</h2>
              </div>
              <span className="chip-action">Shared Data + Adaptive Layout</span>
            </div>

            <div className="grid gap-4 md:grid-cols-3">
              <article className="glass-card rounded-2xl p-4">
                <div className="mb-2 flex items-center gap-2">
                  <Smartphone className="h-4 w-4 text-[var(--clay)]" />
                  <h3 className="font-semibold">iPhone 采集入口</h3>
                </div>
                <p className="text-sm leading-relaxed text-slate-600">
                  用 Share Extension + SwiftData 保存原始链接、标签、抓取时间，并在通勤状态下最少点击完成记录。
                </p>
              </article>

              <article className="glass-card rounded-2xl p-4">
                <div className="mb-2 flex items-center gap-2">
                  <AppWindowMac className="h-4 w-4 text-[var(--teal)]" />
                  <h3 className="font-semibold">Mac 深读工作台</h3>
                </div>
                <p className="text-sm leading-relaxed text-slate-600">
                  在同一个模型层上扩展三栏视图，使用 Command Menu 搜索历史记录，支持备注编辑和批量归档。
                </p>
              </article>

              <article className="glass-card rounded-2xl p-4">
                <div className="mb-2 flex items-center gap-2">
                  <BookMarked className="h-4 w-4 text-[var(--gold)]" />
                  <h3 className="font-semibold">兴趣画像引擎</h3>
                </div>
                <p className="text-sm leading-relaxed text-slate-600">
                  按月份、来源、标签聚合数据，持续回答「我一年都在关注什么」并给出下一步阅读建议。
                </p>
              </article>
            </div>
          </section>
        </main>
      </div>
    </div>
  );
}

export default App;
