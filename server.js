const express = require('express');
const Anthropic = require('@anthropic-ai/sdk');
require('dotenv').config();

const app = express();
app.use(express.json({ limit: '50mb' }));

app.use((req, res, next) => {
  req.setTimeout(120000);
  res.setTimeout(120000);
  next();
});

const anthropic = new Anthropic({
  apiKey: process.env.CLAUDE_API_KEY,
  timeout: 90000
});

async function callClaudeWithRetry(messages, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const message = await anthropic.messages.create({
        model: "claude-3-5-haiku-20241022",
        max_tokens: 4096,
        messages: messages
      });
      return message;
      
    } catch (error) {
      console.log(`Attempt ${attempt} failed:`, error.message);
      
      if (attempt < maxRetries && (
        error.status === 529 ||
        error.status === 500 ||
        error.message.includes('timeout')
      )) {
        const delay = Math.pow(2, attempt) * 1000;
        console.log(`Retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      
      throw error;
    }
  }
}

app.post('/api/process-napi-info', async (req, res) => {
  try {
    const { image_base64 } = req.body;

    console.log('Processing image...');
    
    const message = await callClaudeWithRetry([
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/jpeg",
              data: image_base64
            }
          },
          {
            type: "text",
            text: `Te egy MAGYAR Napi Infó dokumentum elemző vagy.
RENDKÍVÜL FONTOS a pontos szövegfelismerés!

MAGYAR NYELV SPECIFIKUS SZABÁLYOK:
1. ÉKEZETES betűk KÖTELEZŐK:
   - á, é, í, ó, ö, ő, ú, ü, ű
   - HELYES: "Téma:", "Érintett:", "Határidő:", "csütörtök"
   - HELYTELEN: "Tema:", "Erintett:", "Hatarido:", "csutortok"

2. DÁTUM FORMÁTUM:
   - Magyar: 2025.11.13 vagy "november 11."
   - SOHA NE használj cirill karaktereket (З, І, О)!

3. GYAKORI HIBÁK ELKERÜLÉSE:
   - "З" (cirill) → "3" (latin)
   - "І" (cirill) → "I" (latin)
   - "О" (cirill) → "0" (latin)

4. NAPNEVEK (hétfő, kedd, szerda, csütörtök, péntek, szombat, vasárnap)
   - Mindig kisbetűvel kezdve
   - Ékezetekkel helyesen!

EMOJI VÁLASZTÁS:
Minden témához válassz 1 reprezentatív emojit a tartalom alapján:
- Baby/ESL termékek: 🍼
- Pénz/kassa/teljesítmény: 💰
- Ellenőrzés/Mystery Shopping: 🔍
- Élelmiszer/termék: 🛒
- Karácsony/dekoráció/szezonális: 🎄
- Training/oktatás/tréner: 📚
- Display/MPK/monitor: 📺
- Akció/kedvezmény: 🏷️
- Raktár/készlet: 📦
- Magazin/marketing/újság: 📰
- Hűtő/hűtött termék: 🧊
- Időpont/naptár: ⏰
- Figyelmeztetés/fontos: ⚠️
- Statisztika/adat/jelentés: 📊
- Alapértelmezett: 📋

FELADAT:
Elemezd ezt a magyar Napi Infó dokumentumot és küldd vissza JSON formátumban.

KRITIKUS SZABÁLYOK:
1. Olvasd el a TELJES szöveget - NE hagyd ki az első bekezdéseket!
2. Tartsd meg az ÖSSZES tartalmat, beleértve a bevezető mondatokat
3. Táblázatokat strukturáltan elemezd
4. Checkbox állapotokat detektáld (☒ Infó, ☑ Feladat, stb)
5. Ha vannak képek, írd le őket

Minden info blokkhoz add meg:
- tema: A téma címe (ékezetekkel helyesen!)
- erintett: Érintett személy/csoport
- tartalom: TELJES tartalom (minden bekezdés, táblázat, minden!)
- hatarido: Határidő szöveg (ha van)
- emoji: 1 reprezentatív emoji a tartalom alapján
- checkboxes: Bejelölt checkboxok tömbje ["Infó", "Feladat", "Melléklet", "Jelentés"]
- images: Képek leírása (ha van)

FONTOS JSON FORMÁTUMHOZ:
- Escape-eld a backslash karaktereket dupla backslash-sel
- Használj megfelelő JSON escape-elést az idézőjelekhez
- NE legyenek sortörések a stringekben (használj \\n-t)

Válaszd CSAK valid JSON array-t (NO markdown, NO explanation, NO code blocks):
[
  {
    "tema": "Baby ESL - Italos hűtő",
    "erintett": "Mindenki",
    "tartalom": "A balos hűtőben kérjük ellenőrizni...",
    "hatarido": "2025.11.13 csütörtök reggel nyitás",
    "emoji": "🍼",
    "checkboxes": ["Mindenki"],
    "images": []
  }
]

KRITIKUS: A magyar ékezetes karakterek RENDKÍVÜL FONTOSAK!
Mindig PONTOSAN olvasd el a szöveget, különös figyelemmel:
- Terméknevekre (Baby ESL, Szaloncukor, MPK, TROSO, MOPRO)
- Dátumokra és időpontokra (csütörtök, reggel nyitás, stb)
- Magyar ékezetes szavakra (kérjük, feladat, készlet)
- Számokra (vigyázz a cirill karakterekre!)

Tartsd meg a TELJES tartalmat, ne rövidíts!`
          }
        ]
      }
    ]);

    let responseText = message.content[0].text;

    // Clean markdown
    responseText = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    console.log('Parsing JSON response...');
    console.log('Response length:', responseText.length);

    let infoBlocks;
    try {
      infoBlocks = JSON.parse(responseText);
    } catch (parseError) {
      console.error('JSON Parse Error:', parseError.message);
      console.error('Response preview:', responseText.substring(0, 500));
      
      // Try to extract JSON array
      const jsonMatch = responseText.match(/\[[\s\S]*\]/);
      if (jsonMatch) {
        console.log('Attempting to parse extracted JSON...');
        try {
          infoBlocks = JSON.parse(jsonMatch[0]);
        } catch (e) {
          throw new Error(`Failed to parse extracted JSON: ${e.message}`);
        }
      } else {
        throw new Error(`No valid JSON array found in response`);
      }
    }

    console.log(`Successfully parsed ${infoBlocks.length} info blocks`);

    res.json({
      success: true,
      blocks: infoBlocks,
      usage: message.usage
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.status ? `Claude API error ${error.status}` : 'Unknown error'
    });
  }
});

// NEW ENDPOINT: NF visszaküldés OCR processing
app.post('/api/process-nf-visszakuldes', async (req, res) => {
  try {
    const { image_base64 } = req.body;

    console.log('Processing NF visszaküldés image...');
    
    const message = await callClaudeWithRetry([
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/jpeg",
              data: image_base64
            }
          },
          {
            type: "text",
            text: `Te egy MAGYAR NF (Nonfood) visszaküldés dokumentum elemző vagy.
RENDKÍVÜL FONTOS: MINDEN SORT pontosan olvasd be! Ne hagyj ki egyetlen terméket sem!

DOKUMENTUM STRUKTÚRA:
A táblázat oszlopai balról jobbra:
1. Cikkszám - 6 számjegy (KÖTELEZŐ)
2. Cikk megnevezés - termék neve magyar szöveggel
3. WT kód - formátum WT-XX/X-XX (SKIP - NE add vissza!)
4. Bizonylatszám - 5 számjegy (KÖTELEZŐ)
5. Elvi készlet - 1-3 számjegy, a készlet mennyisége

KRITIKUS SZABÁLYOK:
1. Olvasd be MINDEN SORT a táblázatból - egyetlen termék sem maradhat ki!
2. SKIP fejléceket: "Parkside", "PLU", "Cikkszám", "Cikk megnevezés", stb.
3. Egy oldalon TÖBB bizonylatszám is lehet (43531, 33693, 33664, stb.)
4. SZÁMOK PONTOSSÁGA kritikus! Cikkszám = pontosan 6 számjegy, Bizonylatszám = pontosan 5 számjegy

MAGYAR ÉKEZETEK kötelezők a terméknevekben:
- á, é, í, ó, ö, ő, ú, ü, ű
- Helyes: "tölcsérszűrőbetét", "órarugózsinór", "függöny"
- NE használj cirill karaktereket (З→3, І→I, О→0)!

PÉLDA SOR:
"473440 Livarno tölcsérszűrőbetét kutyafül WT-38/1-25 43531 1"
→
{
  "cikkszam": "473440",
  "cikk_megnevezes": "Livarno tölcsérszűrőbetét kutyafül",
  "bizonylat_szam": "43531",
  "elvi_keszlet": 1
}

FONTOS JSON FORMÁTUMHOZ:
- cikkszam, bizonylat_szam: string formátumban (vezetőnullákat megtartva)
- elvi_keszlet: number formátumban (int)
- Escape-eld a speciális karaktereket
- NE használj sortöréseket a stringekben

Válaszd CSAK valid JSON array-t (NO markdown, NO explanation, NO code blocks):
[
  {"cikkszam": "473440", "cikk_megnevezes": "Livarno tölcsérszűrőbetét kutyafül", "bizonylat_szam": "43531", "elvi_keszlet": 1},
  {"cikkszam": "473465", "cikk_megnevezes": "Livarno Led függöny fényfüzér", "bizonylat_szam": "43531", "elvi_keszlet": 2}
]

ELLENŐRZÉS ELŐTT:
- Számold meg hány termék sort látsz → ANNYI JSON objektumot kell visszaadnod!
- Minden cikkszám pontosan 6 számjegy?
- Minden bizonylatszám pontosan 5 számjegy?
- Minden elvi_keszlet pozitív szám?

KEZDD EL AZ ELEMZÉST!`
          }
        ]
      }
    ]);

    let responseText = message.content[0].text;

    // Clean markdown
    responseText = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    console.log('Parsing NF JSON response...');
    console.log('Response length:', responseText.length);

    let termekek;
    try {
      termekek = JSON.parse(responseText);
    } catch (parseError) {
      console.error('JSON Parse Error:', parseError.message);
      console.error('Response preview:', responseText.substring(0, 500));
      
      // Try to extract JSON array
      const jsonMatch = responseText.match(/\[[\s\S]*\]/);
      if (jsonMatch) {
        console.log('Attempting to parse extracted JSON...');
        try {
          termekek = JSON.parse(jsonMatch[0]);
        } catch (e) {
          throw new Error(`Failed to parse extracted JSON: ${e.message}`);
        }
      } else {
        throw new Error(`No valid JSON array found in response`);
      }
    }

    console.log(`Successfully parsed ${termekek.length} termékek`);

    // Validate data
    const invalidItems = termekek.filter(t => 
      !t.cikkszam || t.cikkszam.length !== 6 ||
      !t.bizonylat_szam || t.bizonylat_szam.length !== 5 ||
      !t.elvi_keszlet || t.elvi_keszlet < 1
    );

    if (invalidItems.length > 0) {
      console.warn(`Warning: ${invalidItems.length} items have invalid data`);
    }

    res.json({
      success: true,
      termekek: termekek,
      usage: message.usage
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.status ? `Claude API error ${error.status}` : 'Unknown error'
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});