import 'package:coolapk_flutter/network/api/main.api.dart';
import 'package:coolapk_flutter/network/model/main_init.model.dart'
    as MainInitModel;
import 'package:coolapk_flutter/page/home/tab_page.dart';
import 'package:coolapk_flutter/widget/common_error_widget.dart';
import 'package:coolapk_flutter/page/home/drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // 主页有两个tab
  // 前面是 服务器返回的tab config的 entityId, 后面是PageController
  Map<int, PageController> _controllerMap = {
    // 6390是首页，14468是数码页
    14468: PageController(initialPage: 0),
    6390: PageController(initialPage: 1),
  };

  // 来自服务器的配置数据
  // 包含了 启动图，以及主页两个页面(首页和数码) 的配置
  List<MainInitModel.MainInitModelData> _mainInitModelData;

  // 从服务器获取配置文件
  // 接口 /v6/main/init
  Future<bool> getMainInitModelData() async {
    if (_mainInitModelData != null) return true;
    _mainInitModelData = (await MainApi.getInitConfig()).data;
    return true;
  }

  // 两个页面的配置
  List<MainInitModel.MainInitModelData> get _pageConfigs =>
      _mainInitModelData
          ?.where((element) =>
              element.entityTemplate == "configCard" &&
              element.entityType == "card")
          ?.toList() ??
      [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getMainInitModelData(),
        builder: (context, snap) {
          if (snap.hasError) {
            return CommonErrorWidget(
              error: snap.error,
              onRetry: () {
                // 这样就会触发重试
                setState(() {});
              },
            );
          }
          if (snap.hasData) {
            return _buildFrame();
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  void _gotoTab(int pageEntityId, int page) {
    _controllerMap[pageEntityId].jumpToPage(page);
    // duration: Duration(milliseconds: 700), curve: Curves.easeOutQuart); // animateToPage 会导致经过的页面都会拉取数据...
  }

  @override
  void dispose() {
    _controllerMap.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  GlobalKey<HomePageDrawerState> _homePageDrawerStateKey = GlobalKey();

  // 窗口框架
  Widget _buildFrame() {
    final width = MediaQuery.of(context).size.width;
    final tight = MediaQuery.of(context).size.width < 740; // 是否收起drawer
    final drawer = HomePageDrawer(
      // 先new一个
      key: _homePageDrawerStateKey,
      tabConfigs: _pageConfigs,
      gotoTab: _gotoTab,
    );
    // 不收起drawer时用上
    final innerDrawer = <Widget>[
      Container(
        width: width < 1000 ? 223 : 334,
        child: drawer,
      ),
      const VerticalDivider(
        width: 2,
      ),
    ];
    return Provider.value(
      value: TabController(vsync: this, length: 2),
      child: Builder(
        builder: (context) => Scaffold(
          drawer: tight ? drawer : null, //
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: !tight ? innerDrawer : <Widget>[] // 不收起drawer时用上
              ..add(
                Expanded(
                  child: Center(child: _buildContent(context)), // 主要内容
                ),
              ),
          ),
        ),
      ),
    );
  }

  // 主要内容
  Widget _buildContent(final BuildContext context) {
    return TabBarView(
        controller: Provider.of<TabController>(context, listen: false),
        // 顶层controller
        children: _pageConfigs.map<Widget>((pageConfig) {
          return Container(
            child: PageView(
              onPageChanged: (newPage) {
                _homePageDrawerStateKey?.currentState?.onGotoTab(
                    _pageConfigs.indexOf(pageConfig), (newPage).floor());
              },
              physics: BouncingScrollPhysics(),
              controller: _controllerMap[pageConfig.entityId],
              children: pageConfig.entities.map<Widget>((pageTab) {
                // 这里是子tab
                return TabPage(data: pageTab);
              }).toList(),
            ),
          );
        }).toList());
  }
}
