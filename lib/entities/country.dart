import 'package:cw_core/enumerable_item.dart';

class Country extends EnumerableItem<String> with Serializable<String> {
  const Country({required String code, required this.fullName, required this.countryCode})
      : super(title: fullName, raw: code);

  final String fullName;
  final String countryCode;

  static List<Country> get all => _all.values.toList();

  static const arg = Country(code: 'arg', countryCode: 'AR', fullName: "Argentina");
  static const aus = Country(code: 'aus', countryCode: 'AU', fullName: "Australia");
  static const bgd = Country(code: 'bgd', countryCode: 'BD', fullName: "Bangladesh");
  static const bgr = Country(code: 'bgr', countryCode: 'BG', fullName: "Bulgaria");
  static const bra = Country(code: 'bra', countryCode: 'BR', fullName: "Brazil");
  static const cad = Country(code: 'cad', countryCode: 'CA', fullName: "Canada");
  static const che = Country(code: 'che', countryCode: 'CH', fullName: "Switzerland");
  static const chl = Country(code: 'chl', countryCode: 'CL', fullName: "Chile");
  static const chn = Country(code: 'chn', countryCode: 'CN', fullName: "China");
  static const col = Country(code: 'col', countryCode: 'CO', fullName: "Colombia");
  static const czk = Country(code: 'czk', countryCode: 'CZ', fullName: "Czech Republic");
  static const dnk = Country(code: 'dnk', countryCode: 'DK', fullName: "Denmark");
  static const egy = Country(code: 'egy', countryCode: 'EG', fullName: "Egypt");
  static const eur = Country(code: 'eur', countryCode: 'EU', fullName: "European Union");
  static const gbr = Country(code: 'gbr', countryCode: 'GB', fullName: "United Kingdom");
  static const gha = Country(code: 'gha', countryCode: 'GH', fullName: "Ghana");
  static const gtm = Country(code: 'gtm', countryCode: 'GT', fullName: "Guatemala");
  static const hkg = Country(code: 'hkg', countryCode: 'HK', fullName: "Hong Kong");
  static const hrv = Country(code: 'hrv', countryCode: 'HR', fullName: "Croatia");
  static const hun = Country(code: 'hun', countryCode: 'HU', fullName: "Hungary");
  static const idn = Country(code: 'idn', countryCode: 'ID', fullName: "Indonesia");
  static const isr = Country(code: 'isr', countryCode: 'IL', fullName: "Israel");
  static const ind = Country(code: 'ind', countryCode: 'IN', fullName: "India");
  static const irn = Country(code: 'irn', countryCode: 'IR', fullName: "Iran");
  static const isl = Country(code: 'isl', countryCode: 'IS', fullName: "Iceland");
  static const jpn = Country(code: 'jpn', countryCode: 'JP', fullName: "Japan");
  static const kor = Country(code: 'kor', countryCode: 'KR', fullName: "South Korea");
  static const mar = Country(code: 'mar', countryCode: 'MA', fullName: "Morocco");
  static const mex = Country(code: 'mex', countryCode: 'MX', fullName: "Mexico");
  static const mys = Country(code: 'mys', countryCode: 'MY', fullName: "Malaysia");
  static const nga = Country(code: 'nga', countryCode: 'NG', fullName: "Nigeria");
  static const nor = Country(code: 'nor', countryCode: 'NO', fullName: "Norway");
  static const nzl = Country(code: 'nzl', countryCode: 'NZ', fullName: "New Zealand");
  static const phl = Country(code: 'phl', countryCode: 'PH', fullName: "Philippines");
  static const pak = Country(code: 'pak', countryCode: 'PK', fullName: "Pakistan");
  static const pol = Country(code: 'pol', countryCode: 'PL', fullName: "Poland");
  static const rou = Country(code: 'rou', countryCode: 'RO', fullName: "Romania");
  static const rus = Country(code: 'rus', countryCode: 'RU', fullName: "Russia");
  static const sau = Country(code: 'sau', countryCode: 'SA', fullName: "Saudi Arabia");
  static const swe = Country(code: 'swe', countryCode: 'SE', fullName: "Sweden");
  static const sgp = Country(code: 'sgp', countryCode: 'SG', fullName: "Singapore");
  static const tha = Country(code: 'tha', countryCode: 'TH', fullName: "Thailand");
  static const twn = Country(code: 'twn', countryCode: 'TW', fullName: "Taiwan");
  static const ukr = Country(code: 'ukr', countryCode: 'UA', fullName: "Ukraine");
  static const usa = Country(code: 'usa', countryCode: 'US', fullName: "United States");
  static const ven = Country(code: 'ven', countryCode: 'VE', fullName: "Venezuela");
  static const vnm = Country(code: 'vnm', countryCode: 'VN', fullName: "Vietnam");
  static const saf = Country(code: 'saf', countryCode: 'ZA', fullName: "South Africa");
  static const tur = Country(code: 'tur', countryCode: 'TR', fullName: "Turkey");

  static final _all = {
    Country.arg.raw: Country.arg,
    Country.aus.raw: Country.aus,
    Country.bgd.raw: Country.bgd,
    Country.bgr.raw: Country.bgr,
    Country.bra.raw: Country.bra,
    Country.cad.raw: Country.cad,
    Country.che.raw: Country.che,
    Country.chl.raw: Country.chl,
    Country.chn.raw: Country.chn,
    Country.col.raw: Country.col,
    Country.czk.raw: Country.czk,
    Country.dnk.raw: Country.dnk,
    Country.egy.raw: Country.egy,
    Country.eur.raw: Country.eur,
    Country.gbr.raw: Country.gbr,
    Country.gha.raw: Country.gha,
    Country.gtm.raw: Country.gtm,
    Country.hkg.raw: Country.hkg,
    Country.hrv.raw: Country.hrv,
    Country.hun.raw: Country.hun,
    Country.idn.raw: Country.idn,
    Country.isr.raw: Country.isr,
    Country.ind.raw: Country.ind,
    Country.irn.raw: Country.irn,
    Country.isl.raw: Country.isl,
    Country.jpn.raw: Country.jpn,
    Country.kor.raw: Country.kor,
    Country.mar.raw: Country.mar,
    Country.mex.raw: Country.mex,
    Country.mys.raw: Country.mys,
    Country.nga.raw: Country.nga,
    Country.nor.raw: Country.nor,
    Country.nzl.raw: Country.nzl,
    Country.phl.raw: Country.phl,
    Country.pak.raw: Country.pak,
    Country.pol.raw: Country.pol,
    Country.rou.raw: Country.rou,
    Country.rus.raw: Country.rus,
    Country.sau.raw: Country.sau,
    Country.swe.raw: Country.swe,
    Country.sgp.raw: Country.sgp,
    Country.tha.raw: Country.tha,
    Country.twn.raw: Country.twn,
    Country.ukr.raw: Country.ukr,
    Country.usa.raw: Country.usa,
    Country.ven.raw: Country.ven,
    Country.vnm.raw: Country.vnm,
    Country.saf.raw: Country.saf,
    Country.tur.raw: Country.tur,
  };

  static Country deserialize({required String raw}) => _all[raw]!;

  @override
  bool operator ==(Object other) => other is Country && other.raw == raw;

  @override
  int get hashCode => raw.hashCode ^ title.hashCode;

  String get iconPath => "assets/images/flags/$raw.png";
}
