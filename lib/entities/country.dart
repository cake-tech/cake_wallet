import 'package:cw_core/enumerable_item.dart';
import 'package:collection/collection.dart';

class Country extends EnumerableItem<String> with Serializable<String> {
  const Country({required String code, required this.fullName, required this.countryCode})
      : super(title: fullName, raw: code);

  final String fullName;
  final String countryCode;

  static List<Country> get all => _all.values.toList();

  static const afghanistan = Country(code: 'afg', countryCode: 'AF', fullName: "Afghanistan");
  static const andorra = Country(code: 'and', countryCode: 'AD', fullName: "Andorra");
  static const angola = Country(code: 'ago', countryCode: 'AO', fullName: "Angola");
  static const anguilla = Country(code: 'aia', countryCode: 'AI', fullName: "Anguilla");
  static const antigua_and_barbuda =
      Country(code: 'atg', countryCode: 'AG', fullName: "Antigua and Barbuda");
  static const are = Country(code: 'are', countryCode: 'AE', fullName: "United Arab Emirates");
  static const arg = Country(code: 'arg', countryCode: 'AR', fullName: "Argentina");
  static const arm = Country(code: 'arm', countryCode: 'AM', fullName: "Armenia");
  static const aruba = Country(code: 'abw', countryCode: 'AW', fullName: "Aruba");
  static const aus = Country(code: 'aus', countryCode: 'AU', fullName: "Australia");
  static const aut = Country(code: 'aut', countryCode: 'AT', fullName: "Austria");
  static const aze = Country(code: 'aze', countryCode: 'AZ', fullName: "Azerbaijan");
  static const belize = Country(code: 'blz', countryCode: 'BZ', fullName: "Belize");
  static const bfa = Country(code: 'bfa', countryCode: 'BF', fullName: "Burkina Faso");
  static const bel = Country(code: 'bel', countryCode: 'BE', fullName: "Belgium");
  static const bgd = Country(code: 'bgd', countryCode: 'BD', fullName: "Bangladesh");
  static const bhr = Country(code: 'bhr', countryCode: 'BH', fullName: "Bahrain");
  static const bhs = Country(code: 'bhs', countryCode: 'BS', fullName: "Bahamas");
  static const bhutan = Country(code: 'btn', countryCode: 'BT', fullName: "Bhutan");
  static const bol = Country(code: 'bol', countryCode: 'BO', fullName: "Bolivia");
  static const bra = Country(code: 'bra', countryCode: 'BR', fullName: "Brazil");
  static const brn = Country(code: 'brn', countryCode: 'BN', fullName: "Brunei");
  static const bwa = Country(code: 'bwa', countryCode: 'BW', fullName: "Botswana");
  static const cad = Country(code: 'cad', countryCode: 'CA', fullName: "Canada");
  static const che = Country(code: 'che', countryCode: 'CH', fullName: "Switzerland");
  static const chl = Country(code: 'chl', countryCode: 'CL', fullName: "Chile");
  static const chn = Country(code: 'chn', countryCode: 'CN', fullName: "China");
  static const col = Country(code: 'col', countryCode: 'CO', fullName: "Colombia");
  static const cri = Country(code: 'cri', countryCode: 'CR', fullName: "Costa Rica");
  static const cyp = Country(code: 'cyp', countryCode: 'CY', fullName: "Cyprus");
  static const czk = Country(code: 'czk', countryCode: 'CZ', fullName: "Czech Republic");
  static const deu = Country(code: 'deu', countryCode: 'DE', fullName: "Germany");
  static const dji = Country(code: 'dji', countryCode: 'DJ', fullName: "Djibouti");
  static const dnk = Country(code: 'dnk', countryCode: 'DK', fullName: "Denmark");
  static const dza = Country(code: 'dza', countryCode: 'DZ', fullName: "Algeria");
  static const ecu = Country(code: 'ecu', countryCode: 'EC', fullName: "Ecuador");
  static const egy = Country(code: 'egy', countryCode: 'EG', fullName: "Egypt");
  static const esp = Country(code: 'esp', countryCode: 'ES', fullName: "Spain");
  static const est = Country(code: 'est', countryCode: 'EE', fullName: "Estonia");
  static const eur = Country(code: 'eur', countryCode: 'EU', fullName: "European Union");
  static const fin = Country(code: 'fin', countryCode: 'FI', fullName: "Finland");
  static const fji = Country(code: 'fji', countryCode: 'FJ', fullName: "Fiji");
  static const flk = Country(code: 'flk', countryCode: 'FK', fullName: "Falkland Islands");
  static const fra = Country(code: 'fra', countryCode: 'FR', fullName: "France");
  static const fsm = Country(code: 'fsm', countryCode: 'FM', fullName: "Micronesia");
  static const gab = Country(code: 'gab', countryCode: 'GA', fullName: "Gabon");
  static const gbr = Country(code: 'gbr', countryCode: 'GB', fullName: "United Kingdom");
  static const geo = Country(code: 'geo', countryCode: 'GE', fullName: "Georgia");
  static const gha = Country(code: 'gha', countryCode: 'GH', fullName: "Ghana");
  static const grc = Country(code: 'grc', countryCode: 'GR', fullName: "Greece");
  static const grd = Country(code: 'grd', countryCode: 'GD', fullName: "Grenada");
  static const grl = Country(code: 'grl', countryCode: 'GL', fullName: "Greenland");
  static const gtm = Country(code: 'gtm', countryCode: 'GT', fullName: "Guatemala");
  static const guy = Country(code: 'guy', countryCode: 'GY', fullName: "Guyana");
  static const hkg = Country(code: 'hkg', countryCode: 'HK', fullName: "Hong Kong");
  static const hrv = Country(code: 'hrv', countryCode: 'HR', fullName: "Croatia");
  static const hun = Country(code: 'hun', countryCode: 'HU', fullName: "Hungary");
  static const idn = Country(code: 'idn', countryCode: 'ID', fullName: "Indonesia");
  static const ind = Country(code: 'ind', countryCode: 'IN', fullName: "India");
  static const irl = Country(code: 'irl', countryCode: 'IE', fullName: "Ireland");
  static const irn = Country(code: 'irn', countryCode: 'IR', fullName: "Iran");
  static const isl = Country(code: 'isl', countryCode: 'IS', fullName: "Iceland");
  static const isr = Country(code: 'isr', countryCode: 'IL', fullName: "Israel");
  static const ita = Country(code: 'ita', countryCode: 'IT', fullName: "Italy");
  static const jam = Country(code: 'jam', countryCode: 'JM', fullName: "Jamaica");
  static const jor = Country(code: 'jor', countryCode: 'JO', fullName: "Jordan");
  static const jpn = Country(code: 'jpn', countryCode: 'JP', fullName: "Japan");
  static const kaz = Country(code: 'kaz', countryCode: 'KZ', fullName: "Kazakhstan");
  static const ken = Country(code: 'ken', countryCode: 'KE', fullName: "Kenya");
  static const kir = Country(code: 'kir', countryCode: 'KI', fullName: "Kiribati");
  static const kor = Country(code: 'kor', countryCode: 'KR', fullName: "South Korea");
  static const kwt = Country(code: 'kwt', countryCode: 'KW', fullName: "Kuwait");
  static const lie = Country(code: 'lie', countryCode: 'LI', fullName: "Liechtenstein");
  static const lka = Country(code: 'lka', countryCode: 'LK', fullName: "Sri Lanka");
  static const ltu = Country(code: 'ltu', countryCode: 'LT', fullName: "Lithuania");
  static const lux = Country(code: 'lux', countryCode: 'LU', fullName: "Luxembourg");
  static const lva = Country(code: 'lva', countryCode: 'LV', fullName: "Latvia");
  static const mar = Country(code: 'mar', countryCode: 'MA', fullName: "Morocco");
  static const mex = Country(code: 'mex', countryCode: 'MX', fullName: "Mexico");
  static const mlt = Country(code: 'mlt', countryCode: 'MT', fullName: "Malta");
  static const mnp = Country(code: 'mnp', countryCode: 'MP', fullName: "Northern Mariana Islands");
  static const mtq = Country(code: 'mtq', countryCode: 'MQ', fullName: "Martinique");
  static const mys = Country(code: 'mys', countryCode: 'MY', fullName: "Malaysia");
  static const mwi = Country(code: 'mwi', countryCode: 'MW', fullName: "Malawi");
  static const nga = Country(code: 'nga', countryCode: 'NG', fullName: "Nigeria");
  static const niu = Country(code: 'niu', countryCode: 'NU', fullName: "Niue");
  static const nld = Country(code: 'nld', countryCode: 'NL', fullName: "Netherlands");
  static const nor = Country(code: 'nor', countryCode: 'NO', fullName: "Norway");
  static const nzl = Country(code: 'nzl', countryCode: 'NZ', fullName: "New Zealand");
  static const omn = Country(code: 'omn', countryCode: 'OM', fullName: "Oman");
  static const pak = Country(code: 'pak', countryCode: 'PK', fullName: "Pakistan");
  static const per = Country(code: 'per', countryCode: 'PE', fullName: "Peru");
  static const phl = Country(code: 'phl', countryCode: 'PH', fullName: "Philippines");
  static const pol = Country(code: 'pol', countryCode: 'PL', fullName: "Poland");
  static const pri = Country(code: 'pri', countryCode: 'PR', fullName: "Puerto Rico");
  static const prt = Country(code: 'prt', countryCode: 'PT', fullName: "Portugal");
  static const qat = Country(code: 'qat', countryCode: 'QA', fullName: "Qatar");
  static const rou = Country(code: 'rou', countryCode: 'RO', fullName: "Romania");
  static const rus = Country(code: 'rus', countryCode: 'RU', fullName: "Russia");
  static const saf = Country(code: 'saf', countryCode: 'ZA', fullName: "South Africa");
  static const sau = Country(code: 'sau', countryCode: 'SA', fullName: "Saudi Arabia");
  static const sgp = Country(code: 'sgp', countryCode: 'SG', fullName: "Singapore");
  static const slb = Country(code: 'slb', countryCode: 'SB', fullName: "Solomon Islands");
  static const svk = Country(code: 'svk', countryCode: 'SK', fullName: "Slovakia");
  static const svn = Country(code: 'svn', countryCode: 'SI', fullName: "Slovenia");
  static const swe = Country(code: 'swe', countryCode: 'SE', fullName: "Sweden");
  static const tha = Country(code: 'tha', countryCode: 'TH', fullName: "Thailand");
  static const tkm = Country(code: 'tkm', countryCode: 'TM', fullName: "Turkmenistan");
  static const ton = Country(code: 'ton', countryCode: 'TO', fullName: "Tonga");
  static const tur = Country(code: 'tur', countryCode: 'TR', fullName: "Turkey");
  static const tuv = Country(code: 'tuv', countryCode: 'TV', fullName: "Tuvalu");
  static const twn = Country(code: 'twn', countryCode: 'TW', fullName: "Taiwan");
  static const ukr = Country(code: 'ukr', countryCode: 'UA', fullName: "Ukraine");
  static const ury = Country(code: 'ury', countryCode: 'UY', fullName: "Uruguay");
  static const usa = Country(code: 'usa', countryCode: 'US', fullName: "USA");
  static const ven = Country(code: 'ven', countryCode: 'VE', fullName: "Venezuela");
  static const vnm = Country(code: 'vnm', countryCode: 'VN', fullName: "Vietnam");
  static const vut = Country(code: 'vut', countryCode: 'VU', fullName: "Vanuatu");
  static const btn = Country(code: 'btn', countryCode: 'BT', fullName: "Bhutan");
  static const bgr = Country(code: 'bgr', countryCode: 'BG', fullName: "Bulgaria");
  static const guf = Country(code: 'guf', countryCode: 'GF', fullName: "French Guiana");
  static const bes = Country(code: 'bes', countryCode: 'BQ', fullName: "Caribbean Netherlands");
  static const fro = Country(code: 'fro', countryCode: 'FO', fullName: "Faroe Islands");
  static const cuw = Country(code: 'cuw', countryCode: 'CW', fullName: "Curacao");
  static const msr = Country(code: 'msr', countryCode: 'MS', fullName: "Montserrat");
  static const cpv = Country(code: 'cpv', countryCode: 'CV', fullName: "Cabo Verde");
  static const nfk = Country(code: 'nfk', countryCode: 'NF', fullName: "Norfolk Island");
  static const bmu = Country(code: 'bmu', countryCode: 'BM', fullName: "Bermuda");
  static const vat = Country(code: 'vat', countryCode: 'VA', fullName: "Vatican City");
  static const aia = Country(code: 'aia', countryCode: 'AI', fullName: "Anguilla");
  static const gum = Country(code: 'gum', countryCode: 'GU', fullName: "Guam");
  static const myt = Country(code: 'myt', countryCode: 'YT', fullName: "Mayotte");
  static const mrt = Country(code: 'mrt', countryCode: 'MR', fullName: "Mauritania");
  static const ggy = Country(code: 'ggy', countryCode: 'GG', fullName: "Guernsey");
  static const cck = Country(code: 'cck', countryCode: 'CC', fullName: "Cocos (Keeling) Islands");
  static const blz = Country(code: 'blz', countryCode: 'BZ', fullName: "Belize");
  static const cxr = Country(code: 'cxr', countryCode: 'CX', fullName: "Christmas Island");
  static const mco = Country(code: 'mco', countryCode: 'MC', fullName: "Monaco");
  static const ner = Country(code: 'ner', countryCode: 'NE', fullName: "Niger");
  static const jey = Country(code: 'jey', countryCode: 'JE', fullName: "Jersey");
  static const asm = Country(code: 'asm', countryCode: 'AS', fullName: "American Samoa");
  static const gmb = Country(code: 'gmb', countryCode: 'GM', fullName: "Gambia");
  static const dma = Country(code: 'dma', countryCode: 'DM', fullName: "Dominica");
  static const glp = Country(code: 'glp', countryCode: 'GP', fullName: "Guadeloupe");
  static const ggi = Country(code: 'ggi', countryCode: 'GI', fullName: "Gibraltar");
  static const cmr = Country(code: 'cmr', countryCode: 'CM', fullName: "Cameroon");
  static const atg = Country(code: 'atg', countryCode: 'AG', fullName: "Antigua and Barbuda");
  static const slv = Country(code: 'slv', countryCode: 'SV', fullName: "El Salvador");
  static const pyf = Country(code: 'pyf', countryCode: 'PF', fullName: "French Polynesia");
  static const iot =
      Country(code: 'iot', countryCode: 'IO', fullName: "British Indian Ocean Territory");
  static const vir = Country(code: 'vir', countryCode: 'VI', fullName: "Virgin Islands (U.S.)");
  static const abw = Country(code: 'abw', countryCode: 'AW', fullName: "Aruba");
  static const ago = Country(code: 'ago', countryCode: 'AO', fullName: "Angola");
  static const afg = Country(code: 'afg', countryCode: 'AF', fullName: "Afghanistan");
  static const lbn = Country(code: 'lbn', countryCode: 'LB', fullName: "Lebanon");
  static const hmd =
      Country(code: 'hmd', countryCode: 'HM', fullName: "Heard Island and McDonald Islands");
  static const cok = Country(code: 'cok', countryCode: 'CK', fullName: "Cook Islands");
  static const bvt = Country(code: 'bvt', countryCode: 'BV', fullName: "Bouvet Island");
  static const atf =
      Country(code: 'atf', countryCode: 'TF', fullName: "French Southern Territories");
  static const eth = Country(code: 'eth', countryCode: 'ET', fullName: "Ethiopia");
  static const plw = Country(code: 'plw', countryCode: 'PW', fullName: "Palau");
  static const ata = Country(code: 'ata', countryCode: 'AQ', fullName: "Antarctica");

  static final _all = {
    Country.afghanistan.raw: Country.afghanistan,
    Country.andorra.raw: Country.andorra,
    Country.angola.raw: Country.angola,
    Country.anguilla.raw: Country.anguilla,
    Country.antigua_and_barbuda.raw: Country.antigua_and_barbuda,
    Country.are.raw: Country.are,
    Country.arg.raw: Country.arg,
    Country.arm.raw: Country.arm,
    Country.aruba.raw: Country.aruba,
    Country.aus.raw: Country.aus,
    Country.aut.raw: Country.aut,
    Country.aze.raw: Country.aze,
    Country.belize.raw: Country.belize,
    Country.bfa.raw: Country.bfa,
    Country.bel.raw: Country.bel,
    Country.bgd.raw: Country.bgd,
    Country.bhr.raw: Country.bhr,
    Country.bhs.raw: Country.bhs,
    Country.bhutan.raw: Country.bhutan,
    Country.bol.raw: Country.bol,
    Country.bra.raw: Country.bra,
    Country.brn.raw: Country.brn,
    Country.bwa.raw: Country.bwa,
    Country.cad.raw: Country.cad,
    Country.che.raw: Country.che,
    Country.chl.raw: Country.chl,
    Country.chn.raw: Country.chn,
    Country.col.raw: Country.col,
    Country.cri.raw: Country.cri,
    Country.cyp.raw: Country.cyp,
    Country.czk.raw: Country.czk,
    Country.deu.raw: Country.deu,
    Country.dji.raw: Country.dji,
    Country.dnk.raw: Country.dnk,
    Country.dza.raw: Country.dza,
    Country.ecu.raw: Country.ecu,
    Country.egy.raw: Country.egy,
    Country.esp.raw: Country.esp,
    Country.est.raw: Country.est,
    Country.eur.raw: Country.eur,
    Country.fin.raw: Country.fin,
    Country.fji.raw: Country.fji,
    Country.flk.raw: Country.flk,
    Country.fra.raw: Country.fra,
    Country.fsm.raw: Country.fsm,
    Country.gab.raw: Country.gab,
    Country.gbr.raw: Country.gbr,
    Country.geo.raw: Country.geo,
    Country.gha.raw: Country.gha,
    Country.grc.raw: Country.grc,
    Country.grd.raw: Country.grd,
    Country.grl.raw: Country.grl,
    Country.gtm.raw: Country.gtm,
    Country.guy.raw: Country.guy,
    Country.hkg.raw: Country.hkg,
    Country.hrv.raw: Country.hrv,
    Country.hun.raw: Country.hun,
    Country.idn.raw: Country.idn,
    Country.ind.raw: Country.ind,
    Country.irl.raw: Country.irl,
    Country.irn.raw: Country.irn,
    Country.isl.raw: Country.isl,
    Country.isr.raw: Country.isr,
    Country.ita.raw: Country.ita,
    Country.jam.raw: Country.jam,
    Country.jor.raw: Country.jor,
    Country.jpn.raw: Country.jpn,
    Country.kaz.raw: Country.kaz,
    Country.ken.raw: Country.ken,
    Country.kir.raw: Country.kir,
    Country.kor.raw: Country.kor,
    Country.kwt.raw: Country.kwt,
    Country.lie.raw: Country.lie,
    Country.lka.raw: Country.lka,
    Country.ltu.raw: Country.ltu,
    Country.lux.raw: Country.lux,
    Country.lva.raw: Country.lva,
    Country.mar.raw: Country.mar,
    Country.mex.raw: Country.mex,
    Country.mlt.raw: Country.mlt,
    Country.mnp.raw: Country.mnp,
    Country.mtq.raw: Country.mtq,
    Country.mys.raw: Country.mys,
    Country.mwi.raw: Country.mwi,
    Country.nga.raw: Country.nga,
    Country.niu.raw: Country.niu,
    Country.nld.raw: Country.nld,
    Country.nor.raw: Country.nor,
    Country.nzl.raw: Country.nzl,
    Country.omn.raw: Country.omn,
    Country.pak.raw: Country.pak,
    Country.per.raw: Country.per,
    Country.phl.raw: Country.phl,
    Country.pol.raw: Country.pol,
    Country.pri.raw: Country.pri,
    Country.prt.raw: Country.prt,
    Country.qat.raw: Country.qat,
    Country.rou.raw: Country.rou,
    Country.rus.raw: Country.rus,
    Country.saf.raw: Country.saf,
    Country.sau.raw: Country.sau,
    Country.sgp.raw: Country.sgp,
    Country.slb.raw: Country.slb,
    Country.svk.raw: Country.svk,
    Country.svn.raw: Country.svn,
    Country.swe.raw: Country.swe,
    Country.tha.raw: Country.tha,
    Country.tkm.raw: Country.tkm,
    Country.ton.raw: Country.ton,
    Country.tur.raw: Country.tur,
    Country.tuv.raw: Country.tuv,
    Country.twn.raw: Country.twn,
    Country.ukr.raw: Country.ukr,
    Country.ury.raw: Country.ury,
    Country.usa.raw: Country.usa,
    Country.ven.raw: Country.ven,
    Country.vnm.raw: Country.vnm,
    Country.vut.raw: Country.vut,
    Country.btn.raw: Country.btn,
    Country.bgr.raw: Country.bgr,
    Country.guf.raw: Country.guf,
    Country.bes.raw: Country.bes,
    Country.fro.raw: Country.fro,
    Country.cuw.raw: Country.cuw,
    Country.msr.raw: Country.msr,
    Country.cpv.raw: Country.cpv,
    Country.nfk.raw: Country.nfk,
    Country.bmu.raw: Country.bmu,
    Country.vat.raw: Country.vat,
    Country.aia.raw: Country.aia,
    Country.gum.raw: Country.gum,
    Country.myt.raw: Country.myt,
    Country.mrt.raw: Country.mrt,
    Country.ggy.raw: Country.ggy,
    Country.cck.raw: Country.cck,
    Country.blz.raw: Country.blz,
    Country.cxr.raw: Country.cxr,
    Country.mco.raw: Country.mco,
    Country.ner.raw: Country.ner,
    Country.jey.raw: Country.jey,
    Country.asm.raw: Country.asm,
    Country.gmb.raw: Country.gmb,
    Country.dma.raw: Country.dma,
    Country.glp.raw: Country.glp,
    Country.ggi.raw: Country.ggi,
    Country.cmr.raw: Country.cmr,
    Country.atg.raw: Country.atg,
    Country.slv.raw: Country.slv,
    Country.pyf.raw: Country.pyf,
    Country.iot.raw: Country.iot,
    Country.vir.raw: Country.vir,
    Country.abw.raw: Country.abw,
    Country.ago.raw: Country.ago,
    Country.afg.raw: Country.afg,
    Country.lbn.raw: Country.lbn,
    Country.hmd.raw: Country.hmd,
    Country.cok.raw: Country.cok,
    Country.bvt.raw: Country.bvt,
    Country.atf.raw: Country.atf,
    Country.eth.raw: Country.eth,
    Country.plw.raw: Country.plw,
    Country.ata.raw: Country.ata,
  };

  static final Map<String, String> _cakePayNames = {
    'Slovak Republic': 'Slovakia',
    'Brunei Darussalam': 'Brunei',
    'Federated States of Micronesia': 'Micronesia',
    'Sri lanka': 'Sri Lanka',
    'UAE': 'United Arab Emirates',
    'UK': 'United Kingdom',
    'CuraÃ§ao': "Curacao",
  };

  static Country deserialize({required String raw}) => _all[raw]!;

  static final Map<String, Country> countryByName = {
    for (var country in _all.values) country.fullName: country,
  };

  static Country? fromCakePayName(String name) {
    final normalizedName = _cakePayNames[name] ?? name;
    return countryByName[normalizedName];
  }

  static String getCakePayName(Country country) {
    return _cakePayNames.entries
        .firstWhere(
          (entry) => entry.value == country.fullName,
          orElse: () => MapEntry(country.fullName, country.fullName),
        )
        .key;
  }

  static Country? fromCode(String countryCode) {
    return _all.values.firstWhereOrNull((element) => element.raw == countryCode.toLowerCase());
  }

  @override
  bool operator ==(Object other) => other is Country && other.raw == raw;

  @override
  int get hashCode => raw.hashCode ^ title.hashCode;

  String get iconPath => "assets/images/flags/$raw.png";
}
