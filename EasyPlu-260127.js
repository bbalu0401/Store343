// ==UserScript==
// @name         EasyPLU Helper – v26.01.27
// @namespace    https://easy-plu.knowledge-hero.com/
// @version      3.1.0
// @description  Gyors PLU autokitöltő - Teljes adatbázis!
// @match        https://easy-plu.knowledge-hero.com/*
// @run-at       document-end
// ==/UserScript==

(function () {
"use strict";

/* ═══════════════════════════════════════════════════════════════════════════
🔧 KONFIGURÁCIÓ
═══════════════════════════════════════════════════════════════════════════ */

const CONFIG = {
version: "3.1.0",
logPrefix: "[EasyPLU]",
uiWords: ["plu", "teszt", "gyakorlás", "ellenőrzés", "kilépés", "ean", "kérem"],
};

/* ═══════════════════════════════════════════════════════════════════════════
📦 PLU ADATBÁZIS (Frissítve: 2026.01.27)
═══════════════════════════════════════════════════════════════════════════ */

const PLU_DATA = {
// 🥐 BAKE-OFF
"Almás háromszög": "964",
"Almás-fahéjas fánk": "904",
"Baconos kenyérlángos": "830",
"Belga csokis-meggyes párna": "912",
"Betyár pogácsa": "518",
"Bolognai párna": "987",
"Briós cukor szórattal": "981",
"Buci": "883",
"Börek stangli spenóttal és sajttal": "950",
"Canadier": "868",
"Cookie monster fánk": "920",
"Croustille": "859",
"Csokoládés fánk, csokoládé szórással": "893",
"Csokoládés tekercs": "877",
"Császárbuci": "543",
"Diós bejgli": "880",
"Dupla csokis párna": "986",
"Eperízű színes fánk szórással": "872",
"Fahéjas csiga": "804",
"Fahéjas tekercs": "736",
"Francia baguette": "800",
"Gesztenyés bejgli": "885",
"Gyros párna": "818",
"Hazánk kincsei gyulai kolbászos csípős tekercs": "691",
"Házi vekni": "566",
"Jalapenos-sajtkrémes csiga": "255",
"Kakaós csiga": "998",
"Kovászos burgonyás vekni": "953",
"Kovászos búzakenyér": "824",
"Kovászos cipó": "197",
"Kovászos durum vekni": "813",
"Kovászos krémsajtos-vajas pogácsa": "954",
"Lepénykenyér": "898",
"Light kocka": "892",
"Lávakövön sült durum bagett": "974",
"Mediterrán ciabatta olívás": "673",
"Mediterrán ciabatta, fehér": "447",
"Medve sajtos párna": "869",
"Meggyes-mákos rétes": "837",
"Mogyorókrémes croissant": "942",
"Mogyorós töltött fánk": "861",
"Mákos bejgli": "949",
"Mákos búrkifli": "805",
"Mákos guba": "968",
"Nosztalgia cipó kovásszal": "915",
"Nosztalgia kifli": "9",
"Olívás stangli": "1157",
"Pilis Kovászos rozskenyér": "972",
"Pisztáciás croissant": "803",
"Pizzás csiga": "801",
"Pizzás-sonkás háromszög": "827",
"Pur pur teljeskiőrlésű stangli": "863",
"Rozsos cipó": "561",
"Sajtkrémes zöldfűszeres tekercs": "966",
"Sajtos nosztalgia kifli": "227",
"Sajtos snack rúd": "507",
"Sajtos-sonkás croissant": "902",
"Sajttal szórt pogácsa": "515",
"Sertésvirslis párna": "810",
"Sokmagvas cipó": "891",
"Sonkás-goudás buci": "833",
"Szilvás pur pur batyu": "809",
"Sárgabarackos-túrós párna": "640",
"Tejes kifli": "500",
"Teljes kiőrlésű kakaós csiga": "281",
"Teljes kiőrlésű magvas császárbuci": "812",
"Teljes kiőrlésű nosztalgia kifli": "418",
"Teljes kiőrlésű sokmagvas bagett": "1174",
"Töltött fánk": "875",
"Túrós táska": "982",
"Túrós-csokis párna": "944",
"Vajas croissant": "857",
"Vajas fonott kalács": "1121",
"Vegán croissant": "923",
"Vitajó aranygaluska csiga": "943",
"Vizes zsemle": "540",

// 🥖 BAKEOFF PLU VÁLTOZÁS
"T. Mézeskalács fűszeres tekercs": "50830",
"T. Briós tésztájú croissant": "50804",
"T. Dubai stílusú croissant": "50810",
"T. High protein vaníliás rúd": "50819",
"T. Fahéjas csiga": "50814",
"T. Fahéjas tekercs": "50816",
"T. Fahéjas tekercs": "50817",
"T. Epres-étcsokoládés csiga": "50812",
"T. Csokis croissant": "50805",
"T. Croissant Crème-Brulée ízű": "50808",
"T. Mákos búrkifli": "50824",
"T. Durum Baguette, 300g": "50524",
"T. Baconos kenyérlángos": "50600",
"T. Bajor koszorú lúgos tésztából": "50601",
"T. Bajor perec": "50602",
"T. Betyár pogácsa": "50603",
"T. Bolognai párna": "50604",
"T. Buci": "50544",
"T. Burgonyás pogácsa": "50606",
"T. Burgonyás vekni kovásszal": "50567",
"T. Börek spenóttal és sajttal": "50605",
"T. Ciabatta paradicsomos": "50568",
"T. Crustille": "50522",
"T. Császárbuci": "50543",
"T. Deluxe Pilisi vadkovászos kenyér": "50563",
"T. Durum baguette, 150g": "50523",
"T. Francia Baguette": "50525",
"T. Félbarna kenyér": "50560",
"T. Grillkolbászos csónak": "50607",
"T. Gyros párna": "50608",
"T. Házi vekni": "50566",
"T. Jalapenos-sajtkrémes csiga": "50611",
"T. Kifli teljes kiőrlésű napraforgómaggal": "50511",
"T. Kolbászos lecsós párna": "50612",
"T. Kolbászos tekercs": "50610",
"T. Kovászos búzakenyér": "50570",
"T. Kovászos cipó": "50571",
"T. Kovászos durum vekni": "50572",
"T. Kovászos kenyér": "50573",
"T. Kovászos krémsajtos pogácsa": "50613",
"T. Kovászos kukoricás kenyér": "50574",
"T. Lepény, 300g": "50575",
"T. Lepénykenyér, 100g": "50576",
"T. Light kocka": "50577",
"T. Magvas császárbuci teljes kiőrlésű": "50545",
"T. Mediterrán ciabatta fehér": "50579",
"T. Mediterrán ciabatta olívás": "50578",
"T. Medvesajtos párna": "50615",
"T. Mexikói párna": "50616",
"T. Mini-Calzone par.-mozzarellás": "50618",
"T. Májas kocka": "50614",
"T. Nosztalgia kifli": "50502",
"T. Nosztalgia kifli sajttal": "50504",
"T. Nosztalgia kifli teljes kiőrlésű": "50503",
"T. Nosztalgia vekni kovásszal": "50580",
"T. Olívás stangli, 65g": "50509",
"T. Olívás stangli, 80g": "50510",
"T. Pestos croissant sajtszórással": "50620",
"T. Pilisi kovászos cipó": "50581",
"T. Pizzás csiga": "50621",
"T. Pizzás perec": "50622",
"T. Pizzás-sonkás háromszög": "50623",
"T. Pogácsa sajttal": "50624",
"T. Pulykavirslis croissant": "50625",
"T. Pur Pur stangli teljes kiőrlésű": "50506",
"T. Rozsos cipó": "50561",
"T. Régi idők roppanós kenyere": "50562",
"T. Sajtkrémes zöldfűszeres tekercs": "50626",
"T. Sajtos ciabatta": "50627",
"T. Sajtos perec": "50628",
"T. Sajtos snack rúd": "50507",
"T. Sajtos óriás baguette": "50526",
"T. Sajtos-sonkás croissant": "50629",
"T. Sertésvirslis párna": "50630",
"T. Sokmagvas cipó": "50582",
"T. Sonkás-goudás buci": "50633",
"T. Tejes kifli": "50500",
"T. Teljes kiőrlésű sokmagvas bagett": "50527",
"T. Tökmagos zsemle": "50546",
"T. Túrós-Ricottás Omlós Pogácsa": "50635",
"T. Vegán croissant": "50636",
"T. Vizes zsemle": "50540",
"T. Zsúr vekni": "50583",
"T. Ír joghurtos vekni": "50569",
"T. Szilvás papucs": "50840",
"T. Mézeskalácsos croissant": "50828",
"T. Pekándiós párna": "50836",
"T. Croissant pisztácia töltelékkel": "50807",
"T. Mogyorókrémes croissant": "50831",
"T. Epres-joghurtos croissant": "50813",
"T. Briós cukor szórattal": "50803",
"T. Almás háromszög": "50800",
"T. Meggyes-mákos rétes": "50827",
"T. Csokoládés tekercs": "50809",
"T. Pisztáciás tekercs málnával": "50838",
"T. Pisztáciás kovászos croissant": "50837",
"T. Mákos guba": "50825",
"T. Sárgabarackos-túrós párna": "50839",
"T. Szilvás pur pur batyu": "50841",
"T. Belga csokis-meggyes párna": "50802",
"T. Kakaós csiga": "50821",
"T. Croissant Créme-Brulée izű": "50808",
"T. Kürtöskalács fahéjas": "50823",
"T. Kürtöskalács diós": "50822",
"T. Kakaós csiga teljes kiőrlésű": "50820",
"T. Fahéjas tekercs csokoládéval": "50815",
"T. Mézeskalács emberke": "50829",
"T. Croissant kelt tésztából vaníliás": "50806",
"T. Gesztenyés táska étcsokoládéval": "50818",
"T. Belga csokis tekercs, 300g": "50801",
"T. Dupla csokis párna": "50811",

// 🍬 BONBON
"Banános szeletek étcsokoládéval": "400",
"Galaretka, lédig": "404",
"Kakaós szaloncukor lédig": "423",
"Karamellás szaloncukor lédig": "422",
"Konafetto Bianco tejkrémmel töltött ostyarúd": "405",
"Kókuszos szaloncukor lédig": "421",
"Milky Splash Tejkrémmel töltött karamella": "408",
"Praliné tejcsokoládés sós karamell": "1030",
"Praliné étcsokoládés rumos kakaós": "1028",
"Roshen Candy Nut Karamellás és földimogyorós édesség": "401",
"Roshen Korivka karamell": "407",
"Vegyes zselés bonbon": "409",
"Wawel Brownie Candy málnával": "1002",
"Wawel Fresh&Fruity savanyú zselés": "402",
"Wawel Fresh&Fruity zselés cukor": "403",
"Zselés szaloncukor lédig": "420",

// 🍎 GYÜMÖLCS
"Ananász": "33",
"Avokádó": "34",
"Banán": "1",
"Banán, Bandázsolt kg": "4",
"Bio Banán": "180",
"Cantaloupedinnye db": "161",
"Citrom": "5",
"Cosmic Crips alma": "3507",
"Datolyaszilva db": "37",
"Evelina alma": "106",
"Fairtrade Maracuja db": "52",
"Fehérszőlő": "80",
"Gesztenye": "64",
"Grapefruit piros": "10",
"Gránátalma": "122",
"Héjas dió": "63",
"Japán szilva": "72",
"Kivi": "40",
"Kiwi Gold, db": "41",
"Kékszőlő": "84",
"Kókuszdió": "42",
"Körte Abate Fetel lédig": "140",
"Körte Conference lédig": "142",
"Körte Devici lédig": "144",
"Körte Early Desire lédig": "145",
"Körte Limonera lédig": "146",
"Körte Lucas lédig": "147",
"Körte Packhams lédig": "150",
"Körte Viloms lédig": "149",
"Körte piros": "153",
"Licsi": "45",
"Mandarin": "12",
"Mangó": "46",
"Mini görögdinnye": "176",
"Nagy méretű citrom": "7",
"Nagy méretű narancs": "21",
"Narancs": "20",
"Nashi körte": "148",
"Piros alma Pinova": "113",
"Piros pomelo db": "31",
"Pirosalma Ambrosia": "101",
"Pirosalma Braeburn": "103",
"Pirosalma Crimson snow": "4196",
"Pirosalma Fuji": "107",
"Pirosalma Gala": "108",
"Pirosalma Pink Lady": "4130",
"Pirosalma idared": "110",
"Pirosalma jonagold": "111",
"Pirosalma red chief": "114",
"Pirosszőlő": "82",
"Pomelo": "30",
"Zöld alma kg Granny Smith": "132",
"Zöldalma golden": "130",

// 🦐 TENGERI HERKENTYŰK
"Fehér garnélarák. hámozott, belezett": "1016",
"Főtt kagylóhús": "1025",
"Garnéla farok": "1020",
"Garnéla főtt, tisztított": "1049",
"Kardhal": "1046",
"Panírozott garnéla farok": "1024",
"Prémium tengergyümölcs surimi nélkül": "1023",
"Scampi farok": "1026",
"Tonhal steak": "1017",
"Vénuszkagyló": "1047",

// 🥕 ZÖLDSÉG
"Bio sütőtök": "191",
"Bio uborka": "789",
"Cherry fürtösparadicsom": "258",
"Csemegekukorica": "389",
"Csicsóka": "363",
"Csiperkegomba": "381",
"Cukkini": "291",
"Cékla": "369",
"Fehér hagyma": "330",
"Fejeskáposzta": "300",
"Fejessaláta db": "204",
"Fejessaláta gyökérrel": "202",
"Fekete retek": "222",
"Fokhagyma": "339",
"Fürtösparadicsom": "250",
"Gyömbér": "54",
"Hamburger paradicsom": "252",
"Hazai kápia paprika": "236",
"Hegyes erőspaprika": "230",
"Hokkaido tök": "286",
"Jégcsapretek": "221",
"Jégsaláta": "207",
"Kaliforniai paprika": "234",
"Karalábé": "366",
"Karfiol": "308",
"Kovászolni való uborka": "270",
"Kígyóuborka": "275",
"Kínai Kel": "305",
"Lilahagyma": "331",
"Lollo bionda saláta gyökérrel": "208",
"Multicolor saláta": "212",
"Muskotályos sütőtök": "284",
"Málna paradicsom": "254",
"Padlizsán": "293",
"Pak Choi db": "306",
"Petrezselyemgyökér": "374",
"Petrezselyemgyökér zölddel csomó": "375",
"Piros burgonya lédig": "350",
"Pritamin paprika": "233",
"Póréhagyma": "337",
"Retek csomós": "220",
"Rettertüte": "399",
"Római saláta db": "214",
"Salátauborka": "272",
"Serpenyős burgonya": "359",
"Sárga burgonya lédig": "357",
"Sárgarépa": "371",
"Sütőtök": "283",
"TV paprika": "238",
"Tisztított hagyma": "321",
"Vajretek": "223",
"Vöröshagyma": "320",
"Vöröskáposzta": "302",
"Zeller": "364",
"Zeller zölddel": "365",
"Édesburgonya": "361",
"Édeskömény": "393",
"Ökörszív paradicsom": "256",
"Újhagyma csomós": "332",
};

/* ═══════════════════════════════════════════════════════════════════════════
🔍 PACKHAMS SPECIÁLIS KEZELÉS
═══════════════════════════════════════════════════════════════════════════ */

const PACKHAMS = {
name: "Körte Packhams lédig",
imageA: "10720",
imageB: "10721",
pluA: "150",
pluB: "151",
};

/* ═══════════════════════════════════════════════════════════════════════════
🍥 T. FAHÉJAS TEKERCS SPECIÁLIS KEZELÉS
═══════════════════════════════════════════════════════════════════════════ */

const T_FAHEJAS_TEKERCS = {
name: "T. Fahéjas tekercs",
imageA: "11654", // -> 50816
imageB: "11655", // -> 50817
pluA: "50816",
pluB: "50817",
};

/* ═══════════════════════════════════════════════════════════════════════════
🛠️ SEGÉDFÜGGVÉNYEK
═══════════════════════════════════════════════════════════════════════════ */

function normalize(text) {
return String(text || "").replace(/\s+/g, " ").trim();
}

function isVisible(el) {
if (!el) return false;
const style = getComputedStyle(el);
return (
style.display !== "none" &&
style.visibility !== "hidden" &&
parseFloat(style.opacity || "1") > 0 &&
el.offsetWidth > 30 &&
el.offsetHeight > 20
);
}

function getLogBox() {
let el = document.getElementById("eph-log");
if (!el) {
el = document.createElement("div");
el.id = "eph-log";
el.style.cssText =
"position: fixed; bottom: 18px; left: 18px; z-index: 2147483647; background: rgba(0,0,0,0.86); color: #fff; padding: 7px 10px; border-radius: 10px; font: 12px system-ui, sans-serif; max-width: 80vw; white-space: pre-line; pointer-events: none;";
document.body.appendChild(el);
}
return el;
}

function log(message) {
try {
getLogBox().textContent = CONFIG.logPrefix + " " + message;
} catch (e) {}
}

/* ═══════════════════════════════════════════════════════════════════════════
📝 INPUT KEZELÉS
═══════════════════════════════════════════════════════════════════════════ */

let cachedInput = null;

function findCodeInput() {
if (cachedInput && document.contains(cachedInput) && isVisible(cachedInput)) {
return cachedInput;
}
const inputs = [...document.querySelectorAll("input, textarea")].filter(
  (el) => isVisible(el) && !el.disabled && !el.readOnly
);

inputs.sort((a, b) => {
  const score = (el) => {
    let s = 0;
    if (/(number|tel|text)/i.test(el.type || "")) s += 3;
    if (/(numeric|decimal|tel)/i.test(el.inputMode || "")) s += 3;
    if (el.maxLength > 0 && el.maxLength <= 5) s += 2;
    if (/^\d*$/.test(el.value || "")) s += 1;
    return s;
  };
  return score(b) - score(a);
});

cachedInput = inputs[0] || null;
return cachedInput;
}

function findActionButton() {
const buttons = [...document.querySelectorAll("button, [role='button'], .numpad-button")];
const keywords = ["PLU", "OK", "ENTER", "ELLENŐRZÉS", "KÉSZ"];
const getText = (btn) => {
  return normalize(
    (btn.innerText || btn.textContent || "") +
      " " +
      (btn.getAttribute("aria-label") || "") +
      " " +
      (btn.getAttribute("title") || "")
  ).toUpperCase();
};

buttons.sort((a, b) => b.offsetWidth * b.offsetHeight - a.offsetWidth * a.offsetHeight);

for (const btn of buttons) {
  const text = getText(btn);
  if (keywords.some((kw) => text.includes(kw))) {
    return btn;
  }
}
return null;
}

function typeIntoInput(el, value) {
try {
el.focus();
if (el.isContentEditable) {
el.textContent = "";
el.dispatchEvent(new Event("input", { bubbles: true }));
for (const char of value) {
el.textContent += char;
el.dispatchEvent(new Event("input", { bubbles: true }));
}
} else {
el.value = "";
el.dispatchEvent(new Event("input", { bubbles: true }));
for (const char of value) {
el.value += char;
el.dispatchEvent(new Event("input", { bubbles: true }));
}
el.dispatchEvent(new Event("change", { bubbles: true }));
}
} catch (e) {}
}

function pressEnter(el) {
try {
el.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true }));
el.dispatchEvent(new KeyboardEvent("keyup", { key: "Enter", bubbles: true }));
} catch (e) {}
}

function fillPLU(plu) {
let tries = 0;
function attempt() {
  tries++;
  const input = findCodeInput();

  if (input) {
    typeIntoInput(input, plu);
    const button = findActionButton();
    if (button) {
      button.click();
    } else {
      pressEnter(input);
      try {
        if (input.form) {
          input.form.dispatchEvent(
            new Event("submit", { bubbles: true, cancelable: true })
          );
        }
      } catch (e) {}
    }
    log("PLU beírva: " + plu);
  } else if (tries < 4) {
    setTimeout(attempt, 100);
  } else {
    log("Input nem elérhető");
  }
}
attempt();
}

/* ═══════════════════════════════════════════════════════════════════════════
🔎 TERMÉKNÉV FELISMERÉS
═══════════════════════════════════════════════════════════════════════════ */

const baseMap = (() => {
const map = new Map();
for (const key of Object.keys(PLU_DATA)) {
const base = key.replace(/__(?:A|B|C|D|E|\d+)$/, "");
if (!map.has(base)) map.set(base, []);
map.get(base).push(key);
}
return map;
})();

function scoreHeading(el, inputTop) {
const rect = el.getBoundingClientRect();
const fontSize = parseFloat(getComputedStyle(el).fontSize || "0");
const centerDistance = Math.abs((rect.left + rect.right) / 2 - innerWidth / 2);
const positionBonus = rect.bottom < inputTop - 10 ? 200 : -200;
return fontSize * 10 + Math.max(0, 300 - centerDistance) + positionBonus;
}

function getProductNameAndCard() {
const input = findCodeInput();
const inputTop = input ? input.getBoundingClientRect().top : innerHeight * 0.75;
let headings = [...document.querySelectorAll("h1, h2, [role='heading']")].filter(
  (node) => {
    if (!isVisible(node)) return false;
    const text = normalize(node.textContent || "");
    if (!text || text.length <= 2) return false;
    const lower = text.toLowerCase();
    return !CONFIG.uiWords.some((word) => lower.includes(word));
  }
);

let best = null;
let bestScore = -1;

for (const node of headings) {
  const text = normalize(node.textContent || "");
  if (PLU_DATA[text] || (baseMap.get(text) && baseMap.get(text).length === 1)) {
    const score = scoreHeading(node, inputTop);
    if (score > bestScore) {
      best = node;
      bestScore = score;
    }
  }
}

if (!best) {
  const above = headings.filter(
    (n) => n.getBoundingClientRect().bottom < inputTop - 10
  );
  if (above.length) {
    above.sort((a, b) => scoreHeading(b, inputTop) - scoreHeading(a, inputTop));
    best = above[0];
  } else {
    headings.sort(
      (a, b) =>
        parseFloat(getComputedStyle(b).fontSize || "0") -
        parseFloat(getComputedStyle(a).fontSize || "0")
    );
    best = headings[0];
  }
}

const name = normalize((best && best.textContent) || "");

let card = best;
for (let i = 0; i < 5 && card && card.parentElement; i++) {
  card = card.parentElement;
  if (card.querySelector("img, picture source, [style*='background']")) break;
}

return { name, card: card || document };
}

/* ═══════════════════════════════════════════════════════════════════════════
🖼️ KÉP ID KERESŐ (Packhams / Fahéjas tekercs
═══════════════════════════════════════════════════════════════════════════ */

function findVariantImageId(container, imageA, imageB) {
let bestId = null;
let bestScore = -Infinity;

const nodes = [
  ...container.querySelectorAll("img, picture source, [style*='background']"),
];

for (const el of nodes) {
  let url = "";
  const tag = el.tagName.toLowerCase();
  if (tag === "img") {
    url = el.currentSrc || el.src || el.getAttribute("src") || "";
  } else if (tag === "source") {
    url = el.getAttribute("srcset") || el.getAttribute("data-srcset") || "";
  } else {
    const style = getComputedStyle(el).backgroundImage || "";
    const match = style.match(/url\((['"]?)(.*?)\1\)/i);
    url = match && match[2] ? match[2] : "";
  }

  if (!url) continue;

  const hasA = url.includes(imageA);
  const hasB = url.includes(imageB);
  if (!(hasA || hasB)) continue;

  const rect = el.getBoundingClientRect();
  const area = Math.max(0, rect.width) * Math.max(0, rect.height);
  const centerDistance = Math.abs((rect.left + rect.right) / 2 - innerWidth / 2);
  const input = findCodeInput();
  const inputTop = input ? input.getBoundingClientRect().top : innerHeight * 0.75;
  const positionBonus = rect.bottom < inputTop - 10 ? 300 : -200;
  const centerBonus = Math.max(0, 300 - centerDistance);
  const visibilityBonus = isVisible(el) ? 500 : 0;

  const score =
    visibilityBonus + positionBonus + centerBonus + Math.min(area, 300000);

  const id = hasB ? imageB : imageA;

  if (score > bestScore) {
    bestScore = score;
    bestId = id;
  }
}

return bestId;
}

/* ═══════════════════════════════════════════════════════════════════════════
🎯 PLU KERESÉS
═══════════════════════════════════════════════════════════════════════════ */

function lookupPLU(name) {
const normalized = normalize(name);
if (!normalized) return null;

// Pontos egyezés
if (PLU_DATA[normalized]) return PLU_DATA[normalized];

// Variáns keresés
const variants = baseMap.get(normalized);
if (variants && variants.length === 1) return PLU_DATA[variants[0]];
if (variants && variants.length > 1) return null;

return null;
}

/* ═══════════════════════════════════════════════════════════════════════════
🚀 FŐ LOGIKA
═══════════════════════════════════════════════════════════════════════════ */

let autoEnabled = true;
let lastProcessedKey = "";

function processCard(name, card) {
if (!name) return;

/* 🍐 PACKHAMS */
if (name === PACKHAMS.name) {
  const imageId = findVariantImageId(card, PACKHAMS.imageA, PACKHAMS.imageB);
  if (!imageId) {
    log("Packhams: nem találtam képet");
    return;
  }
  const plu = imageId === PACKHAMS.imageB ? PACKHAMS.pluB : PACKHAMS.pluA;
  const input = findCodeInput();
  if (!(input && input.value)) {
    log("Packhams: " + imageId + " → " + plu);
    fillPLU(plu);
  }
  return;
}

/* 🍥 T. FAHÉJAS TEKERCS */
if (name === T_FAHEJAS_TEKERCS.name) {
  const imageId = findVariantImageId(card, T_FAHEJAS_TEKERCS.imageA, T_FAHEJAS_TEKERCS.imageB);
  if (!imageId) {
    log("T. Fahéjas tekercs: nem találtam képet");
    return;
  }
  const plu = imageId === T_FAHEJAS_TEKERCS.imageB ? T_FAHEJAS_TEKERCS.pluB : T_FAHEJAS_TEKERCS.pluA;
  const input = findCodeInput();
  if (!(input && input.value)) {
    log("T. Fahéjas tekercs: " + imageId + " → " + plu);
    fillPLU(plu);
  }
  return;
}

// Normál PLU keresés
const plu = lookupPLU(name);
if (plu) {
  const input = findCodeInput();
  if (!input) return;
  if ((input.value || "").length > 0) return;
  fillPLU(plu);
} else {
  log("Nincs PLU: " + name);
}
}

/* ═══════════════════════════════════════════════════════════════════════════
⏰ TICK (változatlan)
═══════════════════════════════════════════════════════════════════════════ */

let pending = false;
let plannedSignature = "";
let plannedName = "";

function getImageSignature(scope) {
const urls = new Set();
const addUrl = (url) => {
if (!url) return;
url = String(url);
if (/\d{5,}/.test(url) || url.includes("/plufiles/")) {
urls.add(url);
}
};
scope.querySelectorAll("img").forEach((img) => {
  addUrl(img.currentSrc || img.src);
  addUrl(img.getAttribute("src"));
  addUrl(img.getAttribute("data-src"));
  const srcset = img.getAttribute("srcset") || img.getAttribute("data-srcset") || "";
  srcset.split(",").forEach((part) => addUrl(part.trim().split(" ")[0]));
});

scope.querySelectorAll("picture source").forEach((source) => {
  const srcset =
    source.getAttribute("srcset") || source.getAttribute("data-srcset") || "";
  srcset.split(",").forEach((part) => addUrl(part.trim().split(" ")[0]));
});

const ids = [];
for (const url of urls) {
  const match = url.match(/(\d{5,})/);
  if (match) ids.push(match[1]);
}
ids.sort();
return ids.join("|");
}

function tick() {
if (!autoEnabled) return;
if (pending) return;
pending = true;

requestAnimationFrame(() => {
  pending = false;

  const { name, card } = getProductNameAndCard();
  const signature = getImageSignature(card);

  if (name !== plannedName || signature !== plannedSignature) {
    plannedName = name;
    plannedSignature = signature;

    const key = name + "|" + signature;
    if (key !== lastProcessedKey) {
      processCard(name, card);
      lastProcessedKey = key;
    }
  }
});
}

/* ═══════════════════════════════════════════════════════════════════════════
🎬 INICIALIZÁLÁS
═══════════════════════════════════════════════════════════════════════════ */

log("v" + CONFIG.version + " - 288 termék (Auto ON)");

const observer = new MutationObserver(tick);
observer.observe(document.documentElement, {
subtree: true,
childList: true,
characterData: true,
attributes: true,
attributeFilter: ["src", "srcset", "style"],
});

setInterval(tick, 400);
window.addEventListener("scroll", tick, { passive: true });

window.addEventListener("keydown", (e) => {
if (e.altKey && (e.key === "o" || e.key === "O")) {
autoEnabled = !autoEnabled;
log("Auto " + (autoEnabled ? "ON" : "OFF"));
}
if (e.altKey && (e.key === "p" || e.key === "P")) {
  const { name, card } = getProductNameAndCard();
  if (name === PACKHAMS.name) {
    const imageId = findVariantImageId(card, PACKHAMS.imageA, PACKHAMS.imageB);
    if (imageId) {
      const plu = imageId === PACKHAMS.imageB ? PACKHAMS.pluB : PACKHAMS.pluA;
      fillPLU(plu);
    } else {
      log("Packhams: nincs kép");
    }
    return;
  }
  if (name === T_FAHEJAS_TEKERCS.name) {
    const imageId = findVariantImageId(card, T_FAHEJAS_TEKERCS.imageA, T_FAHEJAS_TEKERCS.imageB);
    if (imageId) {
      const plu = imageId === T_FAHEJAS_TEKERCS.imageB ? T_FAHEJAS_TEKERCS.pluB : T_FAHEJAS_TEKERCS.pluA;
      fillPLU(plu);
    } else {
      log("T. Fahéjas tekercs: nincs kép");
    }
    return;
  }

  const plu = lookupPLU(name);
  if (plu) {
    fillPLU(plu);
  } else {
    log("Nincs PLU: " + name);
  }
}
});

tick();
})();
