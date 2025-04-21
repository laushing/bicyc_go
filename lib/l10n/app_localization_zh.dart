import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get english => '英文';

  @override
  String get appTitle => '單車出行樂';

  @override
  String get dashboard => '主頁';
  
  @override
  String get map => '地圖';
  
  @override
  String get rewards => '獎勵';
  
  @override
  String get profile => '個人檔案';
  
  @override
  String get settings => '設定';
  
  @override
  String get language => '語言';
  
  @override
  String get planRoute => '規劃路線';
  
  @override
  String get createCustomRoute => '創建自定義路線';
  
  @override
  String get saveRoute => '保存路線';
  
  @override
  String get cancel => '取消';
  
  @override
  String get addPoint => '添加路線點';
  
  @override
  String get editRouteName => '編輯路線名稱';
  
  @override
  String get routeNameHint => '在此輸入路線名稱';
  
  @override
  String get pointAdded => '路線點添加成功！';

  @override
  String get routeSaved => '路線保存成功！';

  @override
  String get routeSaveError => '保存路線時出錯！請重試。';

  @override
  String get needMorePoints => '需要更多路線點來規劃路線！';

  @override
  String get tapToAddPoint => '點擊地圖添加路線點';

  @override
  String get routeSelected => '路線選擇成功！';

  @override
  String get startNavigation => '開始導航';

  @override
  String get navigationStarted => '導航已開始！';

  @override
  String get routeName => '路線名稱';

  @override
  String get plannedDateTime => '計劃日期和時間';

  @override
  String get date => '日期';

  @override
  String get time => '時間';
  
  @override
  String get location => '位置';

  @override
  String get addPointToRoute => '添加路線點到路線';

  @override
  String get noRoutesAvailable => '沒有可用的路線。請先創建一條路線。';

  @override
  String get failedToLoadRoutes => '無法加載路線。請檢查您的網絡連接或稍後再試。';

  @override
  String get start => '開始';

  @override
  String get end => '結束';

  @override
  String get loadRoutesError => '加載路線時出錯！請重試。';
  

  @override
  String get chineseTraditional => '中文（繁体）';

}