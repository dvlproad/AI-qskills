#!/bin/sh
# podspec_normalize.sh — 规范化 podspec：子库摘要转注释 + 重构 description 区
# 用法:
#   sh podspec_normalize.sh --spec-dir <目录>       # 嵌套模式（dvlproadSpecs）【必传】
#   sh podspec_normalize.sh --project-dir <目录>     # 扁平模式（CJUIKit）【必传】

SPEC_ROOT=""
PROJECT_ROOT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --spec-dir) SPEC_ROOT="$2"; shift 2 ;;
        --project-dir) PROJECT_ROOT="$2"; shift 2 ;;
        -h|--help)
            echo "用法:"
            echo "  sh podspec_normalize.sh --spec-dir <目录>       # 嵌套模式（dvlproadSpecs）"
            echo "  sh podspec_normalize.sh --project-dir <目录>     # 扁平模式（CJUIKit）"
            exit 0 ;;
        *) echo "❌ 未知参数: $1，请使用 --spec-dir 或 --project-dir"; exit 1 ;;
    esac
done

if [ -z "$SPEC_ROOT" ] && [ -z "$PROJECT_ROOT" ]; then
    echo "❌ 错误：必须指定 --spec-dir 或 --project-dir"
    echo "用法：sh podspec_normalize.sh --spec-dir <目录>  # 嵌套模式"
    echo "      sh podspec_normalize.sh --project-dir <目录>  # 扁平模式"
    exit 1
fi

python3 << PYEOF
import os, re, sys, glob

spec_root = os.path.expanduser('$SPEC_ROOT') if '$SPEC_ROOT' else None
project_root = os.path.expanduser('$PROJECT_ROOT') if '$PROJECT_ROOT' else None

# --- 目录存在性 + 参数一致性验证 ---
def die(msg):
    print(f'❌ {msg}')
    sys.exit(1)

if spec_root:
    if not os.path.isdir(spec_root):
        die(f'目录不存在: {spec_root}')
    has_podspec = bool(glob.glob(os.path.join(spec_root, '*.podspec')))
    if has_podspec:
        die(f'--spec-dir 指向的目录包含 .podspec 文件（检测到 {len(glob.glob(os.path.join(spec_root, "*.podspec")))} 个），请改用 --project-dir')

if project_root:
    if not os.path.isdir(project_root):
        die(f'目录不存在: {project_root}')
    has_podspec = bool(glob.glob(os.path.join(project_root, '*.podspec')))
    if not has_podspec:
        die(f'--project-dir 指向的目录没有 .podspec 文件，请改用 --spec-dir')

TRANSLATIONS = {
    'UI': 'UI界面',
    'Base': '基础模块',
    'Network': '网络模块',
    'Manager': '管理模块',
    'Mediator': '中介者模块',
    'Util': '工具模块',
    'Helper': '帮助类',
    'Category': '分类',
    'Model': '数据模型',
    'Database': '数据库模块',
    'Logic': '逻辑模块',
    'ViewModel': '视图模型',
    'Toast': 'Toast提示',
    'Alert': '弹窗',
    'ActionSheet': '操作列表',
    'HUD': 'HUD提示',
    'ProgressHUD': '进度HUD',
    'IndicatorProgressHUD': '指示器进度HUD',
    'JSONProgressHUD': 'JSON进度HUD',
    'Refresh': '刷新',
    'Login': '登录模块',
    'Register': '注册',
    'Logout': '登出',
    'Phone': '手机号',
    'Password': '密码',
    'Third': '第三方',
    'Quick': '快捷',
    'ForgetPassword': '忘记密码',
    'PhoneCode': '手机验证码',
    'UsernamePassword': '用户名密码',
    'Theme': '主题',
    'ThemeSetting': '主题设置',
    'Common': '通用模块',
    'Request': '网络请求',
    'Upload': '上传',
    'BaseUtil': '基础工具',
    'BaseBottom': '基础底部视图',
    'BaseCenter': '基础居中视图',
    'PopupInfo': '弹出信息',
    'PopupAnimation': '弹出动画',
    'PopupDrop': '弹出下拉',
    'ShowAnyView': '任意视图展示',
    'Birthday': '生日选择',
    'Sex': '性别选择',
    'Area': '地区选择',
    'Height': '身高选择',
    'Weight': '体重选择',
    'Header': '头部视图',
    'Footer': '底部视图',
    'Cell': '单元格',
    'TableViewCell': '表格单元格',
    'TableViewSectionHeader': '表格分区头',
    'CollectionViewCell': '集合单元格',
    'FlowLayout': '流式布局',
    'FixedRowColumnLayout': '固定行列数均分布局',
    'HorizontalLayout': '水平布局',
    'CardSwitchLayout': '卡片切换布局',
    'CoverFlowLayout': '封面浏览布局',
    'WaterLayout': '瀑布流布局',
    'MainSubLayout': '主次布局',
    'MainSubLastLayout': '主次尾部布局',
    'Image': '图片',
    'Button': '按钮',
    'GradientButton': '渐变按钮',
    'BarButton': '条按钮',
    'OneTwoThreeButton': '一二三按钮',
    'PlayButtons': '播放按钮',
    'BottomButtonsView': '底部按钮视图',
    'Label': '标签',
    'TextField': '文本输入框',
    'TextView': '文本视图',
    'ScrollView': '滚动视图',
    'NavigationBar': '导航栏',
    'Toolbar': '工具栏',
    'Slider': '滑条',
    'Window': '窗口',
    'View': '视图',
    'Controller': '控制器',
    'Picker': '选择器',
    'DatePickerView': '日期选择视图',
    'DateText': '日期文本',
    'SearchBar': '搜索栏',
    'SearchList': '搜索列表',
    'ProcessLine': '流程线',
    'ProgressView': '进度视图',
    'ScheduleLineView': '进度线视图',
    'Share': '分享',
    'Map': '地图',
    'Location': '定位',
    'QRCode': '二维码',
    'Pinyin': '拼音',
    'Keyboard': '键盘',
    'Call': '电话',
    'LaunchImage': '启动图',
    'Data': '数据处理',
    'Date': '日期',
    'Format': '格式化',
    'User': '用户模块',
    'Order': '订单模块',
    'City': '城市模块',
    'Address': '地址模块',
    'Service': '服务模块',
    'Environment': '环境配置',
    'Constant': '常量',
    'Permission': '权限',
    'Authorization': '授权',
    'AppInfo': '应用信息',
    'Device': '设备信息',
    'Hook': 'Hook方法',
    'Web': 'Web视图',
    'OperationQueue': '操作队列',
    'Timer': '定时器',
    'Gesture': '手势',
    'Drag': '拖拽',
    'Shake': '摇动',
    'Move': '移动',
    'Select': '选择',
    'Enable': '启用',
    'Empty': '空数据',
    'Loading': '加载',
    'Privacy': '隐私',
    'Policy': '协议',
    'Rule': '规则',
    'Update': '更新',
    'Monitor': '监控',
    'ThirdLogin': '第三方登录',
    'PhoneLogin': '手机号登录',
    'PasswordLogin': '密码登录',
    'ThirdParty': '第三方平台',
    'Social': '社交',
    'Umeng': '友盟',
    'BMKMap': '百度地图',
    'BaiduMap': '百度地图',
    'Other': '其他',
    'Public': '公共模块',
    'ExtralItem': '额外项',
    'ImageChooseView': '图片选择视图',
    'ImagesList': '图片列表',
    'AddDeletePickUpload': '添加删除选择上传',
    'AddDeleteContainer': '添加删除容器',
    'ActionDataSource': '数据源处理',
    'ActionImage': '图片操作',
    'ActionText': '文本操作',
    'ActionImageMainSub': '图片主次操作',
    'BottomBlank': '底部空白弹窗',
    'CenterBlank': '居中空白弹窗',
    'EffectAndCornerHelper': '效果圆角帮助',
    '4ViewCategory': '四视图分类',
    'Bottom_CustomAddToolbar': '底部自定义工具栏',
    'Bottom_AgreeOrNo': '底部同意选择',
    'Center_Other': '居中其他',
    'Popup': '弹出视图',
    'Show': '展示动画',
    'Drop': '下拉动画',
    'SystemImagePickerController': '系统图片选择器',
    'CustomImagePickerController': '自定义图片选择器',
    'ImagePickerPermissionManager': '图片选择权限管理',
    'ImagePickerController': '图片选择控制器',
    'ImagePickerControllerUtil': '图片选择控制器工具',
    'RecordView': '录音视图',
    'ChatKeyboardMoreView': '聊天键盘更多视图',
    'EmojiUtil': '表情工具',
    'EmojiView': '表情视图',
    'ChatToolbar': '聊天工具栏',
    'ChatKeyboardView': '聊天键盘视图',
    'CJHomeCollectionView': '首页集合视图',
    'CJOpenCollectionView': '展开集合视图',
    'CQMenuListKit': '菜单列表',
    'CJGRView': '手势视图',
    'CJGRScrollView': '手势滚动视图',
    'CGRectHelper': 'CGRect帮助类',
    'CGRectAdjustHelper': 'CGRect调整帮助',
    'CGRectSubHelper': 'CGRect子视图帮助',
    'Extension': '扩展方法',
    'PraiseView': '点赞视图',
    'CommentView': '评论视图',
    'PhotoContainerView': '图片容器视图',
    'VideoView': '视频视图',
    'PhotoBrowser': '图片浏览器',
    'CJFriendCirclePraiseView': '朋友圈点赞视图',
    'CJFriendCircleCommentView': '朋友圈评论视图',
    'CJFriendCirclePhotoContainerView': '朋友圈图片容器',
    'CJFriendCircleVideoView': '朋友圈视频视图',
    'CJRefreshWithJSON': 'JSON刷新',
    'CJRefreshView': '刷新视图',
    'CJMJRefreshComponent': 'MJ刷新组件',
    'CJDataEmptyView': '空数据视图',
    'CJScaleHeadView': '缩放头部视图',
    'CJBaseOverlayTheme': '覆盖层主题',
    'HUDAnimation': 'HUD动画',
    'AlertView_Normal': '普通弹窗',
    'AlertView_Horizontal': '水平弹窗',
    'AlertView_Image': '图片弹窗',
    'mas_distribute': 'Masonry分布',
    'CJToast': 'Toast提示',
    'CQAlert': '弹窗',
    'CQActionSheet': '操作列表',
    'CQHUD': 'HUD提示',
    'CQToast': 'Toast提示',
    'CQRefresh': '刷新',
    'LotteryDraw': '抽奖',
    'UpdateContentPopupView': '更新内容弹窗',
    'PrivacyPolicy': '隐私协议',
    'CJShareSheet': '分享列表',
    'ShareUtil': '分享工具',
    'CJSocialUtil': '社交工具',
    'AppDelegate': '应用代理',
    'CJMap': '地图',
    'CJBaiduMap': '百度地图',
    'BBXPBase': '乘客端基础',
    'BBXClientSDK': '客户端SDK',
    'BBXPEnvironment': '乘客端环境',
    'BBXPNetwork': '乘客端网络',
    'BBXPDatabase': '乘客端数据库',
    'BBXPLoginUI': '乘客端登录UI',
    'BBXPLogin_Category': '乘客端登录分类',
    'BBXPUser': '用户数据',
    'BBXPServiceLineAndStation': '服务线路站点',
    'BBXPAddress': '地址数据',
    'BBXPCity': '城市数据',
    'BBXPCityPack': '城市数据包',
    'BBXPOrder': '订单数据',
    'BBXPassengerEnvironment': '乘客端环境',
    'BBXPassengerNetwork': '乘客端网络',
    'BBXPUmengModule': '友盟模块',
    'BBXPBMKMapModule': '百度地图模块',
    'BBXDriverEnvironment': '司机端环境',
    'BBXDriverNetwork': '司机端网络',
    'BBXPPlaceChooseUI': '地点选择UI',
    'BBXPPlaceChoose_Category': '地点选择分类',
    'BBXPPlaceOrderUI': '下单UI',
    'BBXPPlaceOrder_Category': '下单分类',
    'CommonUI': '通用UI',
    'CJDemoUser': '用户数据模型',
    'TableView': '表格视图',
    'CollectionView': '集合视图',
    'CollectionViewDataSource': '集合视图数据源',
    'ImagePickerKit': '图片选择',
    'CQDatePickerKit': '日期选择',
    'CQItemPicker': '事项选择器',
    'CJPopupCreater': '弹窗创建器',
    'CJOverlayView': '覆盖层视图',
    'CJBaseEffectKit': '基础效果',
    'CJBaseOverlayKit': '基础覆盖层',
    'CQOverlayKit': '覆盖层组件',
    'CQPopupContentKit': '弹窗内容组件',
    'CQPopupAnimation': '弹窗动画',
    'CQPopupContainerAnimation': '弹窗容器动画',
    'CQPopupCreater_Base': '弹窗创建器基础',
    'CQPopupCreater_Other': '弹窗创建器其他',
    'CQProcessKit': '流程组件',
    'CQSearchKit': '搜索组件',
    'CQShareSheet': '分享列表',
    'CQShareUMengKit': '友盟分享',
    'CQThirdLoginView': '第三方登录视图',
    'CQUserService': '用户服务',
    'CQUserService_Login': '用户登录服务',
    'CQUserService_Login_Third': '用户第三方登录服务',
    'CQLoginService': '登录服务',
    'CQLoginInfoInputViewModel': '登录信息输入视图模型',
    'CQButtonKit': '按钮组件',
    'CQCellAndHeaderCollect': '单元格头部收集',
    'CQEffectKit': '效果组件',
    'CQImageAddDeleteListKit': '图片添加删除列表',
    'CQMdeiaVideoFrameKit': '媒体视频帧',
    'CQMenuListKit': '菜单列表',
    'UICollectionViewCJHelper': '集合视图帮助类',
    'UserPropertyCJHelper': '用户属性帮助类',
    'CJCollectionViewDataSource': '集合视图数据源',
    'CJCollectionViewLayout': '集合视图布局',
    'CJImagePickerKit': '图片选择',
    'CJOpenListKit': '展开列表',
    'CJFeatureListKit': '功能列表',
    'CJFriendCircleComponentView': '朋友圈组件',
    'CJGRKit': '手势组件',
    'CJChat': '聊天模块',
    'CJDemoCommon': 'Demo通用',
    'CJDemoMemoryTrainingModule': '记忆力训练模块',
    'CJDemoModuleLogin': '登录模块',
    'CJDemoModuleMainUI': '主界面UI',
    'CJDemoModuleMine': '我的模块',
    'CJDemoPasdLogin': '密码登录',
    'CJDemoPhoneLogin': '手机号登录',
    'CJDemoPhoneVerify': '手机验证',
    'CJDemoThirdLogin': '第三方登录',
    'CJDemoService': '服务模块',
    'CJThirdPlatform': '第三方平台',
    'CJPopupAnimation': '弹窗动画',
    'CQActionCollectionView': '操作集合视图',
    'CQActionListView': '操作列表视图',
    'CQActionTableViewCell': '操作表格单元格',
    'CQAppNetwork': '应用网络模块',
    'CQAppNetwork_Login': '应用登录网络',
    'CQUserDetailModel': '用户详情数据模型',
    'CQPopUpAnimateView': '弹窗动画视图',
    'CJContentModel': '内容数据模型',
    'CJFileModel': '文件数据模型',
    'CJCollectionViewManager': '集合视图管理器',
    'CJTableViewManager': '表格视图管理器',
    'CJListDataModel': '列表数据模型',
    'CJModel': '数据模型',
    'CJDataModel': '数据模型',
    'CJPageModel': '分页数据模型',
    'CJLoadMoreModel': '加载更多数据模型',
    'CJSearchModel': '搜索数据模型',
    'CJTableViewSectionModel': '表格分区数据模型',
    'CJCollectionViewSectionModel': '集合视图分区数据模型',
    'CJPageControl': '分页控件',
    'CJBanner': '横幅',
    'CJCarousel': '轮播',
    'CJBannerControl': '横幅控制',
    'CJBannerProtocol': '横幅协议',
    'CJBannerView': '横幅视图',
    'CJBannerCollectionView': '横幅集合视图',
    'CJBannerCell': '横幅单元格',
    'CJBannerPageControl': '横幅分页控件',
    'CJBannerAutoScroll': '横幅自动滚动',
    'CJTableViewController': '表格视图控制器',
    'CJCollectionViewController': '集合视图控制器',
    'CJTableDataController': '表格数据控制器',
    'CJCollectionDataController': '集合数据控制器',
    'CJTableViewCell': '表格视图单元格',
    'CJCollectionViewCell': '集合视图单元格',
    'CJDemoModuleService': 'Demo模块服务',
    'CJDemoModuleNetwork': 'Demo模块网络',
    'CJDemoModuleCache': 'Demo模块缓存',
    'CJBaseCell': '基础单元格',
    'CJTableViewSectionHeader': '表格分区头',
    'CJCollectionViewSectionHeader': '集合分区头',
    'CJTableViewDataSource': '表格数据源',
    'CJCollectionViewDataSource': '集合数据源',
}

def generate_summary(subspec_name):
    if subspec_name in TRANSLATIONS:
        return TRANSLATIONS[subspec_name]
    for key, val in sorted(TRANSLATIONS.items(), key=lambda x: -len(x[0])):
        if subspec_name.endswith(key) or subspec_name == key:
            return val
    words = re.findall(r'[A-Z][a-z]*|[a-z]+|\d+', subspec_name)
    translated = []
    for w in words:
        if w in TRANSLATIONS:
            translated.append(TRANSLATIONS[w])
        elif w.upper() in TRANSLATIONS:
            translated.append(TRANSLATIONS[w.upper()])
        else:
            translated.append(w)
    result = ''.join(translated)
    return '' if result == subspec_name else result

total_modified = 0
total_subspecs = 0

# --- 文件发现 ---
if project_root:
    spec_paths = sorted(glob.glob(os.path.join(project_root, '*.podspec')))
    for spec_path in spec_paths:
        pod_name = os.path.splitext(os.path.basename(spec_path))[0]
        # --- 处理逻辑（与嵌套模式共用） ---
        with open(spec_path, encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()

        # 1. Find subspecs and their summaries
        subspec_stack = []
        subspec_info = []
        for i, line in enumerate(lines):
            m = re.match(r'^(\s*)s{1,2}\.subspec\s+[\'"]([^\'"]+)[\'"]\s+do', line)
            if not m:
                if re.match(r'^\s*end\s', line) and subspec_stack:
                    subspec_stack.pop()
                continue
            indent = m.group(1)
            name = m.group(2)
            subspec_stack.append(name)
            full_name = '/'.join(subspec_stack)

            def is_code_comment(text):
                # 易错: 必须检出后缀为 end/if/def（无空格）及含 word.word 模式的注释掉的代码行
                # 如 # end、# if、# s.dependency，漏匹配会导致它们被当作"用户注释"而跳过自动生成
                return bool(re.search(r'\w+\.\w+', text)) or text.split()[0] in ('if', 'end', 'def') if text.split() else False

            comment = ''
            has_user_comment = False
            j = i - 1
            while j >= 0:
                prev = lines[j].strip()
                if prev.startswith('#'):
                    ct = prev.lstrip('#').strip()
                    if not is_code_comment(ct):
                        comment = ct
                        has_user_comment = True
                        break
                    else:
                        break
                elif prev:
                    break
                j -= 1

            summary_from_body = ''
            depth = 0
            k = i + 1
            while k < len(lines) and depth >= 0:
                lk = lines[k]
                level = depth + 1
                sv = 's' + 's' * level      # depth 0→ss(父级), depth 1→sss(子级)
                sm = re.search(rf'{re.escape(sv)}\.summary\s*=\s*[\'"](.+?)[\'"]', lk)
                # 易错: 只取 depth==0 的 summary。regex ss 会同时匹配 ss.summary 和 sss.summary，
                # 若不限制 depth，子级的 sss.summary 会覆盖父级（如 CJManager 曾取到 CJSuspendWindowManager 的 summary）
                if sm and depth == 0:
                    summary_from_body = sm.group(1)
                if re.match(r'^\s*s{1,2}\.subspec\s+', lk):
                    depth += 1
                elif re.match(r'^\s*end\s*', lk):
                    depth -= 1
                k += 1

            summary = summary_from_body or comment or generate_summary(name)
            subspec_info.append((i, name, full_name, summary, indent, has_user_comment))

        if not subspec_info:
            continue

        total_subspecs += len(subspec_info)

        # 2. Build new content
        new_lines = []
        summary_inserted = {}

        i = 0
        while i < len(lines):
            line = lines[i]
            m = re.match(r'^(\s*)s{1,2}\.subspec\s+[\'"]([^\'"]+)[\'"]\s+do', line)
            if m:
                name = m.group(2)
                info = None
                for si in subspec_info:
                    if si[0] == i:
                        info = si
                        break
                if info:
                    _, _, _, summary, indent, has_user_comment = info
                    if not has_user_comment:
                        new_lines.append(f'{indent}# {summary}\n')

                    new_lines.append(line)
                    i += 1
                    depth = 1
                    while i < len(lines) and depth > 0:
                        cl = lines[i]
                        if re.match(r'^\s*#?\s*sss?\.summary\s*=', cl):
                            i += 1
                            continue
                        if re.match(r'^\s*s{1,2}\.subspec\s+', cl):
                            depth += 1
                            for si in subspec_info:
                                if si[0] == i:
                                    _, _, _, child_summary, _, child_has_comment = si
                                    if not child_has_comment and child_summary:
                                        child_indent = re.match(r'^\s*', cl).group(0)
                                        new_lines.append(f'{child_indent}# {child_summary}\n')
                                    break
                        elif re.match(r'^\s*end\s*', cl):
                            depth -= 1
                        new_lines.append(cl)
                        i += 1
                    continue
            new_lines.append(line)
            i += 1

        # 3. Update/insert s.description heredoc
        pod_summary = ''
        for line in new_lines:
            sm = re.search(r's\.summary\s*=\s*[\'"](.+?)[\'"]', line)
            if sm:
                pod_summary = sm.group(1)
                break

        desc_lines = []
        desc_lines.append(f'                 {pod_summary}，可按需独立引入：\n')
        for si in subspec_info:
            _, _, full_name, summary, indent, _ = si
            desc_lines.append(f'                 • {pod_name}/{full_name} - {summary}\n')
        desc_lines.append('\n')
        desc_lines.append('                 每个子库可独立引入，详见各子库描述。\n')

        desc_start = None
        desc_end = None
        for i, line in enumerate(new_lines):
            sm = re.search(r's\.description\s*=', line)
            if sm:
                if '<<-' in line or '<<~' in line or '<<' in line:
                    desc_start = i
                    j = i + 1
                    while j < len(new_lines):
                        if new_lines[j].strip() == 'DESC':
                            desc_end = j + 1
                            break
                        j += 1
                else:
                    desc_start = i
                    desc_end = i + 1
                break

        if desc_start is not None:
            new_lines[desc_start:desc_end] = [
                f'  s.description  = <<-DESC\n',
                *desc_lines,
                f'                 DESC\n',
            ]
        else:
            insert_at = None
            for i, line in enumerate(new_lines):
                if re.match(r'^\s*s\.summary\s*=', line):
                    insert_at = i + 1
                    break
            if insert_at:
                new_lines[insert_at:insert_at] = [
                    f'  s.description  = <<-DESC\n',
                    *desc_lines,
                    f'                 DESC\n',
                ]

        content_new = ''.join(new_lines)
        with open(spec_path, encoding='utf-8', errors='ignore') as f:
            content_old = f.read()

        if content_new != content_old:
            with open(spec_path, 'w', encoding='utf-8') as f:
                f.write(content_new)
            total_modified += 1
            print(f'  ✅ {pod_name} — {len(subspec_info)} subspecs')
else:
    for pod_name in sorted(os.listdir(spec_root)):
        pod_dir = os.path.join(spec_root, pod_name)
        if not os.path.isdir(pod_dir):
            continue
        versions = sorted([d for d in os.listdir(pod_dir) if os.path.isdir(os.path.join(pod_dir, d))])
        if not versions:
            continue
        latest = versions[-1]
        spec_path = os.path.join(pod_dir, latest, f'{pod_name}.podspec')
        if not os.path.exists(spec_path):
            continue

        with open(spec_path, encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()

        # 1. Find subspecs and their summaries
        subspec_stack = []
        subspec_info = []
        for i, line in enumerate(lines):
            m = re.match(r'^(\s*)s{1,2}\.subspec\s+[\'"]([^\'"]+)[\'"]\s+do', line)
            if not m:
                if re.match(r'^\s*end\s', line) and subspec_stack:
                    subspec_stack.pop()
                continue
            indent = m.group(1)
            name = m.group(2)
            subspec_stack.append(name)
            full_name = '/'.join(subspec_stack)

            def is_code_comment(text):
                # 易错: 必须检出后缀为 end/if/def（无空格）及含 word.word 模式的注释掉的代码行
                # 如 # end、# if、# s.dependency，漏匹配会导致它们被当作"用户注释"而跳过自动生成
                return bool(re.search(r'\w+\.\w+', text)) or text.split()[0] in ('if', 'end', 'def') if text.split() else False

            comment = ''
            has_user_comment = False
            j = i - 1
            while j >= 0:
                prev = lines[j].strip()
                if prev.startswith('#'):
                    ct = prev.lstrip('#').strip()
                    if not is_code_comment(ct):
                        comment = ct
                        has_user_comment = True
                        break
                    else:
                        break
                elif prev:
                    break
                j -= 1

            summary_from_body = ''
            depth = 0
            k = i + 1
            while k < len(lines) and depth >= 0:
                lk = lines[k]
                level = depth + 1
                sv = 's' + 's' * level      # depth 0→ss(父级), depth 1→sss(子级)
                sm = re.search(rf'{re.escape(sv)}\.summary\s*=\s*[\'"](.+?)[\'"]', lk)
                # 易错: 只取 depth==0 的 summary。regex ss 会同时匹配 ss.summary 和 sss.summary，
                # 若不限制 depth，子级的 sss.summary 会覆盖父级（如 CJManager 曾取到 CJSuspendWindowManager 的 summary）
                if sm and depth == 0:
                    summary_from_body = sm.group(1)
                if re.match(r'^\s*s{1,2}\.subspec\s+', lk):
                    depth += 1
                elif re.match(r'^\s*end\s*', lk):
                    depth -= 1
                k += 1

            summary = summary_from_body or comment or generate_summary(name)
            subspec_info.append((i, name, full_name, summary, indent, has_user_comment))

        if not subspec_info:
            continue

        total_subspecs += len(subspec_info)

        # 2. Build new content
        new_lines = []
        summary_inserted = {}

        i = 0
        while i < len(lines):
            line = lines[i]
            m = re.match(r'^(\s*)s{1,2}\.subspec\s+[\'"]([^\'"]+)[\'"]\s+do', line)
            if m:
                name = m.group(2)
                info = None
                for si in subspec_info:
                    if si[0] == i:
                        info = si
                        break
                if info:
                    _, _, _, summary, indent, has_user_comment = info
                    if not has_user_comment:
                        new_lines.append(f'{indent}# {summary}\n')

                    new_lines.append(line)
                    i += 1
                    depth = 1
                    while i < len(lines) and depth > 0:
                        cl = lines[i]
                        if re.match(r'^\s*sss?\.summary\s*=', cl):
                            i += 1
                            continue
                        if re.match(r'^\s*s{1,2}\.subspec\s+', cl):
                            depth += 1
                            for si in subspec_info:
                                if si[0] == i:
                                    _, _, _, child_summary, _, child_has_comment = si
                                    if not child_has_comment and child_summary:
                                        child_indent = re.match(r'^\s*', cl).group(0)
                                        new_lines.append(f'{child_indent}# {child_summary}\n')
                                    break
                        elif re.match(r'^\s*end\s*', cl):
                            depth -= 1
                        new_lines.append(cl)
                        i += 1
                    continue
            new_lines.append(line)
            i += 1

        # 3. Update/insert s.description heredoc
        pod_summary = ''
        for line in new_lines:
            sm = re.search(r's\.summary\s*=\s*[\'"](.+?)[\'"]', line)
            if sm:
                pod_summary = sm.group(1)
                break

        desc_lines = []
        desc_lines.append(f'                 {pod_summary}，可按需独立引入：\n')
        for si in subspec_info:
            _, _, full_name, summary, indent, _ = si
            desc_lines.append(f'                 • {pod_name}/{full_name} - {summary}\n')
        desc_lines.append('\n')
        desc_lines.append('                 每个子库可独立引入，详见各子库描述。\n')

        desc_start = None
        desc_end = None
        for i, line in enumerate(new_lines):
            sm = re.search(r's\.description\s*=', line)
            if sm:
                if '<<-' in line or '<<~' in line or '<<' in line:
                    desc_start = i
                    j = i + 1
                    while j < len(new_lines):
                        if new_lines[j].strip() == 'DESC':
                            desc_end = j + 1
                            break
                        j += 1
                else:
                    desc_start = i
                    desc_end = i + 1
                break

        if desc_start is not None:
            new_lines[desc_start:desc_end] = [
                f'  s.description  = <<-DESC\n',
                *desc_lines,
                f'                 DESC\n',
            ]
        else:
            insert_at = None
            for i, line in enumerate(new_lines):
                if re.match(r'^\s*s\.summary\s*=', line):
                    insert_at = i + 1
                    break
            if insert_at:
                new_lines[insert_at:insert_at] = [
                    f'  s.description  = <<-DESC\n',
                    *desc_lines,
                    f'                 DESC\n',
                ]

        content_new = ''.join(new_lines)
        with open(spec_path, encoding='utf-8', errors='ignore') as f:
            content_old = f.read()

        if content_new != content_old:
            with open(spec_path, 'w', encoding='utf-8') as f:
                f.write(content_new)
            total_modified += 1
            print(f'  ✅ {pod_name} ({latest}) — {len(subspec_info)} subspecs')

print(f'\nDone: {total_modified} files modified, {total_subspecs} subspecs processed')
PYEOF
