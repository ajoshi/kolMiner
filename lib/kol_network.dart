import 'dart:async';
import 'dart:convert';
import 'dart:io';

class KolNetwork {
  static const String BASE_URL = "https://www.kingdomofloathing.com/";

  static const String LOGIN_POSTFIX = "login.php";
  static const String MAINT_POSTFIX = "maint.php";

  final String appName;
  String _forAppName;

  String _username;
  String _password;
  String _awsAlb;
  String _phpsessid;
  bool _isLoggedIn = false;
  String _charPwd = "";
  String _playerId;
  String _pwdHash;

  KolNetwork(this.appName) : _forAppName = "for=$appName";

  bool isLoggedIn() {
    return _isLoggedIn;
  }

  Future<NetworkResponseCode> login(
    String username,
    String password,
  ) async {
    _username = username;
    _password = password;
    try {
      Uri firstLoginUrl = Uri.parse(BASE_URL + LOGIN_POSTFIX);
      var httpClient = new HttpClient();
      var loginPageRequest = await httpClient.getUrl(firstLoginUrl);
      var initialLoginPageResponse = await loginPageRequest.close();
      var realLoginPageUrl = initialLoginPageResponse.redirects[0].location;
      if (realLoginPageUrl != null &&
          !realLoginPageUrl.toString().startsWith("/")) {
        return NetworkResponseCode.ROLLOVER;
      }

      var loginUrl = BASE_URL + realLoginPageUrl.toString();
      loginUrl = loginUrl +
          "&loggingin=Yup."
          "&promo="
          "&mrstore="
          "&secure=1"
          "&loginname=$_username/q"
          "&password=$_password"
          "&submitbutton=Log+In&$_forAppName";

      Uri tempUri = Uri.parse(loginUrl);

      var realLoginRequest = await httpClient.postUrl(tempUri);
      var realResponse = await realLoginRequest.close();

      _updateCookies(realResponse.cookies);
      httpClient.close(force: false);

      if (_phpsessid == null) {
        return NetworkResponseCode.FAILURE;
      }

      // get the charpwd as well so we can make arbitrary requests
      await _getCharPwdAndHash();

      _isLoggedIn = true;
      // tell the consumer we logged in
      return NetworkResponseCode.SUCCESS;
    } on IOException catch (_) {
      // not sure what we can do here.
      return NetworkResponseCode.FAILURE;
    }
  }

  /// Logging in doesn't get us all the player data, but hitting the charpane does
  /// So we check the charpane for the pwdhash and charpwd
  Future<bool> _getCharPwdAndHash() async {
    var response = await makeRequest("charpane.php?$_forAppName");
    if (response.responseCode == NetworkResponseCode.SUCCESS) {
      var charInfoHtml = response.response;
      _playerId = _getBetween2Strings(charInfoHtml, "playerid = ", ";");
      _pwdHash = _getBetween2Strings(charInfoHtml, "pwdhash = \"", "\"");

      _charPwd =
          _getBetween2Strings(charInfoHtml, "setCookie('charpwd', winW, ", ",");
      return true;
    }
    return false;
  }

  /// Fetches player data from api.php. Returns null on failure (bad network?)
  Future<Map> getPlayerData() async {
    var statusresponse =
        await makeRequestWithQueryParams("api.php", "what=status");
    //{"playerid":"2129446","name":"ajoshi","hardcore":"1","ascensions":"319",
    // "path":"22","sign":"Vole","roninleft":"308","casual":"0","drunk":"13",
    // "full":"4","turnsplayed":"760080","familiar":"213","hp":"359","mp":"54",
    // "meat":"95332","adventures":"42","level":"14","rawmuscle":"12920",

    // "rawmysticality":"13323","rawmoxie":"32584","basemuscle":"113",
    // "basemysticality":"115","basemoxie":"180","familiarexp":400,"class":"6",
    // "lastadv":{"id":"1026","name":"The Naughty Sorceress' Tower",
    // "link":"place.php?whichplace=nstower","container":"place.php?whichplace=nstower"},
    // "title":"14","pvpfights":"70","maxhp":394,"maxmp":446,"spleen":"0",
    // "muscle":223,"mysticality":225,"moxie":345,"famlevel":25,"locked":false,
    // "limitmode":0,"daysthisrun":"4","equipment":{"hat":"2069","shirt":"6719",
    // "pants":"9574","weapon":"6815","offhand":"9133","acc1":"5039","acc2":"7967",
    // "acc3":"9322","container":"9082","familiarequip":"2573","fakehands":0,"cardsleeve":0},
    // "stickers":[0,0,0],"soulsauce":0,"fury":0,"pastathrall":0,"pastathralllevel":1,
    // "folder_holder":["17","15","22","00","00"],"eleronkey":"<SOME HASH>",
    // "flag_config":{"noinvpops":0,"fastdecking":"1","devskills":0,"shortcharpane":0,
    // "lazyinventory":0,"compactfights":"1","poppvpsearch":0,"questtracker":0,
    // "charpanepvp":"1","australia":"1","fffights":"1","compactchar":0,"noframesize":0,
    // "fullnesscounter":"1","nodevdebug":0,"noquestnudge":0,"nocalendar":0,"alwaystag":0,
    // "clanlogins":"1","quickskills":"1","hprestorers":0,"hidejacko":0,"anchorshelf":0,
    // "showoutfit":0,"wowbar":"1","swapfam":0,"hidefamfilter":0,"invimages":0,
    // "showhandedness":0,"acclinks":"1","invadvancedsort":"1","powersort":0,
    // "autodiscard":0,"unfamequip":"1","invclose":0,"sellstuffugly":0,
    // "oneclickcraft":0,"dontscroll":0,"multisume":"1","threecolinv":"1","profanity":"1",
    // "tc_updatetitle":0,"tc_alwayswho":0,"tc_times":0,"tc_combineallpublic":0,
    // "tc_eventsactive":0,"tc_hidebadges":0,"tc_colortabs":0,"tc_modifierkey":0,
    // "tc_tabsonbottom":0,"chatversion":"1","aabosses":0,"compacteffects":0,
    // "slimhpmpdisplay":"1","ignorezonewarnings":"1","whichpenpal":"4",
    // "compactmanuel":"1","hideefarrows":0,"questtrackertiny":0,"questtrackerscroll":0,
    // "disablelovebugs":0,"eternalmrj":"1","autoattack":0,"topmenu":0},"recalledskills":0,
    // "freedralph":0,"mcd":0,"pwd":"a629273e74c4cef59001974fa47a8556",
    // "rollover":1533353398,"turnsthisrun":692,"familiar_wellfed":0,
    // "intrinsics":{"518f53443c261c2b61ea11fe8716a715":["Spirit of Peppermint",
    // "snowflake","518f53443c261c2b61ea11fe8716a715","168"]},"familiarpic":"xoskeleton",
    // "pathname":"Standard",
    // "effects":{"0bf172ccba65be4fdc4c0f908325b5c1":["Everything Looks Yellow",66,"eyes",null,790]}}
    if (statusresponse.responseCode == NetworkResponseCode.SUCCESS) {
      Map parsedResponse = json.decode(statusresponse.response);
      //int maxMp = parsedResponse["maxmp"];
      //     var advs = parsedResponse["adventures"];
      return parsedResponse;
    }
    return null;
  }

  /// Given a bigString, finds the substring between the two passed in Strings
  String _getBetween2Strings(
      String bigString, String startString, String endString) {
    var startIndex = bigString.indexOf(startString);
    if (startIndex != -1) {
      startIndex = startIndex + startString.length;
      var endIndex = bigString.indexOf(endString, startIndex);
      return bigString.substring(startIndex, endIndex);
    }
    return "";
  }

  /// not really logging out- just null out fields so they can't be used
  void logout() {
    _isLoggedIn = false;
    _username = null;
    _password = null;
    _phpsessid = null;
    _awsAlb = null;
    _charPwd = null;
    _pwdHash = null;
  }

  /// Make a network request for the given url and the urlParams. Params do not
  /// start with & or ?. Eg. "which=1&b=2"
  /// The 'for' param is added automatically.
  /// Performs GET requests by default, but can also perform PUTs
  Future<NetworkResponse> makeRequestWithQueryParams(
      String baseUrl, String params,
      {HttpMethod method}) async {
    return makeRequest("$baseUrl?$_forAppName&pwd=$_pwdHash&$params",
        method: method);
  }

  /// Make a network request for a given url. Defaults to GET, but can make PUT requests as well
  Future<NetworkResponse> makeRequest(String url,
      {HttpMethod method = HttpMethod.GET}) async {
    //  print("call to $url");
    try {
      var httpClient = new HttpClient();
      var headerCookie =
          "PHPSESSID=$_phpsessid; AWSALB=$_awsAlb; charPwd=$_charPwd";
      HttpClientRequest httpRequest;
      if (method == HttpMethod.POST) {
        // post if requested
        httpRequest = await httpClient.postUrl(Uri.parse(BASE_URL + url));
      } else {
        // else default is get
        httpRequest = await httpClient.getUrl(Uri.parse(BASE_URL + url));
      }
      httpRequest.headers
        ..add("PHPSESSID", _phpsessid)
        ..add("AWSALB", _awsAlb)
        ..add("cookie", headerCookie);

      var resp = await httpRequest.close();

      if (resp.redirects != null && resp.redirects.isNotEmpty) {
        var redirectUrl = resp.redirects[0].location;
        if (redirectUrl != null &&
            redirectUrl.toString().contains(MAINT_POSTFIX)) {
          return NetworkResponse(NetworkResponseCode.ROLLOVER, "");
        }
        if (redirectUrl != null) {
          return NetworkResponse(NetworkResponseCode.EXPIRED_HASH, "");
        }
      }
      // login.php?invalid=1
      _updateCookies(resp.cookies);

      //  TODO handle network failures while making request
      try {
        return new NetworkResponse(NetworkResponseCode.SUCCESS,
            await resp.transform(utf8.decoder).single);
      } catch (_) {
        // couldn't parse the response. Send back empty string?
        return new NetworkResponse(NetworkResponseCode.SUCCESS, "");
      }
    } on IOException catch (_) {
      return NetworkResponse(NetworkResponseCode.FAILURE, "");
    }
  }

  /// Call this with the server cookie response so we can update our cookies
  void _updateCookies(List<Cookie> cookies) {
    for (var cook in cookies) {
      if (cook.name == "PHPSESSID") {
        _phpsessid = cook.value;
      }
      if (cook.name == "AWSALB") {
        _awsAlb = cook.value;
      }
    }
  }
}

class NetworkResponse {
  final NetworkResponseCode responseCode;
  final String response;

  NetworkResponse(this.responseCode, this.response);
}

enum NetworkResponseCode {
  SUCCESS,
  FAILURE,
  ROLLOVER,
  EXPIRED_HASH,
}

enum HttpMethod {
  // I only care about these two
  GET,
  POST,
}
