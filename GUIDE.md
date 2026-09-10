# WinSux — Guide d'utilisation
Par ELIAS

Script d'optimisation Windows tout-en-un : installe les outils de base, allège le système, réinstalle **automatiquement** le pilote NVIDIA proprement, applique des tweaks de performance CPU/GPU/réseau, et nettoie Windows.

## Prérequis
- Windows 10/11 (Home/Pro/LTSC/IoT/Server)
- Connexion Internet
- **GPU NVIDIA** pour la partie pilote (le reste s'applique quand même sans NVIDIA)
- Une fresh install de Windows recommandée (le script désactive Defender, UAC, BitLocker et d'autres protections système — voir avertissements en bas)

## Contenu du dossier
Copie **tout le dossier tel quel** (ne pas séparer `WinSux.ps1` de `Temp/`) :
```
WinSux-main/
├── WinSux.ps1           <- script principal, à lancer
├── AllowScripts.cmd     <- à lancer d'abord si PowerShell bloque les scripts
├── LICENSE
├── README.md
├── GUIDE.md             <- ce fichier
├── _backup_avant_audit/ <- copie des scripts d'origine avant l'audit
└── Temp/
    ├── stepone.ps1      <- étape 1 (safe mode)
    ├── steptwo.ps1      <- étape 2 (boot normal)
    ├── 7zip.exe, ddu.exe, directx.exe, inspector.exe
    ├── vcredist*.exe (C++ redistributables)
    └── reg.reg, settimerresolutionservice.cs, start2.txt
```

## Comment copier sur un autre PC
- Clé USB, disque externe, ou partage réseau : copie le dossier `WinSux-main` en entier.
- Rien à installer ni télécharger en plus, tout est déjà dans `Temp/`.

## Étapes d'utilisation

### 0. (Si besoin) Débloquer l'exécution des scripts
Si Windows refuse de lancer `WinSux.ps1`, double-clique **`AllowScripts.cmd`** d'abord, choisis l'option **1**. Il autorise l'exécution des scripts PowerShell et débloque tous les fichiers du dossier.

### 1. Lancer le script principal
Double-clique **`WinSux.ps1`** → "Exécuter avec PowerShell". Une popup UAC apparaît, accepte-la (le script s'auto-élève en administrateur).

### 2. Phase 1 — automatique
Le script :
- mémorise le nom exact du GPU NVIDIA (avant que DDU efface le pilote)
- copie les fichiers de `Temp/` vers `C:\Windows\Temp`
- installe 7-Zip, les runtimes C++, DirectX
- extrait DDU (Display Driver Uninstaller)
- programme `stepone.ps1` et `steptwo.ps1` pour s'exécuter automatiquement au prochain démarrage
- active le démarrage en mode sans échec
- **redémarre tout seul** après 5 secondes

### 3. Phase 2 — mode sans échec, automatique
`stepone.ps1` se lance automatiquement :
- désactive Windows Defender, UAC, protections diverses
- désinstalle les pilotes GPU/audio existants (NVIDIA, AMD, Intel, Realtek) via DDU
- **redémarre à nouveau tout seul**

### 4. Phase 3 — boot normal, **entièrement automatique**
`steptwo.ps1` se lance automatiquement :
- suppression des applications heritees (OneDrive, brlapi, GameInput, Remote Desktop, ancien Snipping Tool)
- **téléchargement et installation automatiques du pilote NVIDIA** : identification du modèle, appel à l'API NVIDIA, téléchargement avec barre de progression, allègement du paquet, installation silencieuse
  - *aucune action requise* — une sélection manuelle n'est proposée qu'en dernier recours si les serveurs NVIDIA sont injoignables
- profil NVIDIA Profile Inspector : power management max perf, G-Sync activé, **Resizable BAR forcé globalement**, Ultra Low Latency désactivé (voir plus bas)
- **installation silencieuse de MSI Afterburner** + limite de puissance portée au maximum de la carte et cible thermique à 83 °C via `nvidia-smi`
- optimisations : GameDVR off, HAGS on, MPO off, Nagle off, SysMain off, MSI mode GPU, DPC par cœur
- optimisations CPU : pas de core parking, EPP performance, ramp-up « rocket », kernel non pagé, NTFS accéléré, prefetcher off, mitigations Spectre/Meltdown désactivées
- plan d'alimentation Ultimate Performance, résolution du minuteur système
- nettoyage disque + point de restauration
- **rapport de vérification** : 19 contrôles relus depuis l'état réel du système, affichés OK/ÉCHEC et enregistrés dans `C:\ProgramData\Optimisation\rapport.txt`
- **redémarrage final automatique** (20 s, le temps de lire le rapport)

## Politique thermique
Le pack cherche la performance **sous charge**, pas des fréquences bloquées au maximum en permanence :
- **C-states laissés actifs** et **état minimal du processeur à 5 %** — les épingler à 100 % ajoute 15-25 °C au repos et fait *perdre* des performances, un package plus chaud atteignant sa limite thermique plus tôt et boostant moins loin.
- La réactivité vient de `EPP=0` + montée en fréquence « rocket », qui répondent en microsecondes.
- La **limite de puissance GPU est portée au maximum de la carte** et la cible thermique fixée à **83 °C** via `nvidia-smi`. Aucune tâche planifiée ne rejoue ce réglage : MSI Afterburner en est désormais le seul propriétaire, sans quoi les deux s'écrasaient mutuellement toutes les 15 minutes.
- Le GPU n'est **plus forcé** dans son P-state maximum au repos (économie de 20-30 W et 10-15 °C sur un bureau inactif).

## Deux arbitrages GPU à connaître

**Resizable BAR forcé globalement.** Activer le ReBAR dans le BIOS ne suffit pas : le pilote NVIDIA ne l'applique qu'aux jeux figurant dans sa propre liste blanche, et le désactive silencieusement partout ailleurs. Le profil Inspector force donc `rBAR - Feature`, `rBAR - Options` et `rBAR - Size Limit` sur le profil de base, ce qui l'étend à tous les titres. Gain typique : 2 à 5 %, davantage dans les jeux gourmands en VRAM.
→ *C'est le réglage le moins vérifié du pack : les identifiants numériques de ces trois options proviennent de la communauté, pas d'une documentation NVIDIA. S'ils sont erronés, l'import les ignore simplement — aucun risque, mais aucun effet non plus. Pour vérifier, ouvre `inspector.exe`, section « 5 - Common ».*

**Ultra Low Latency désactivé.** Ce mode limite la file de rendu pour réduire la latence, au prix de quelques images par seconde quand la carte est le facteur limitant. Le pack privilégie désormais les FPS bruts.
→ *Pour revenir en arrière : Panneau de configuration NVIDIA → Gérer les paramètres 3D → Mode faible latence → **Ultra**.*

## Réglage fin du GPU — à faire une fois, à la main
Le script installe MSI Afterburner et débloque le contrôle de tension, mais **n'applique volontairement aucun offset de fréquence, de mémoire ou de tension**. Ces valeurs dépendent de l'exemplaire de puce : un profil copié d'ailleurs donne au mieux rien, au pire des écrans noirs. Voici la marche à suivre, par ordre de rendement :

1. **Undervolt par la courbe** (`Ctrl+F` dans Afterburner) — le meilleur réglage disponible. Choisis un point autour de **0,900-0,950 V**, monte-le à la fréquence que la carte atteignait à pleine tension, aplatis la courbe à droite, applique. Résultat typique : mêmes performances, 30 à 50 W et une dizaine de degrés en moins.
2. **Offset mémoire** — commence à **+500 MHz**, par paliers de 250. Attention : la GDDR6X/GDDR7 corrige ses erreurs en silence, donc au-delà du point stable tu ne verras **pas** d'artefacts, tu perdras simplement des performances. Valide toujours avec un benchmark chiffré, pas à l'œil.
3. **Offset GPU** — +150 à +250 MHz en général, gain modeste.

Valide chaque étape avec 20-30 minutes de charge réelle avant de passer à la suivante, et enregistre dans un profil Afterburner appliqué au démarrage.

## Gains réalistes
Les tweaks OS/registre donnent typiquement **1 à 4 %** en jeu. Les vrais leviers restent dans le BIOS et ne peuvent pas être automatisés par un script :
- **XMP / EXPO** sur la mémoire — souvent le plus gros gain isolé (5-15 % selon les jeux)
- **Resizable BAR / Above 4G Decoding**
- Refroidissement : une courbe de ventilation correcte vaut plus que n'importe quelle clé de registre

### 5. Terminé
Après le dernier redémarrage, le PC est prêt.

## Temps d'exécution
15-30 minutes au total, incluant 2 redémarrages automatiques. Plus aucune pause manuelle en fonctionnement normal.

## Ce qui est volontairement CONSERVÉ
Pour éviter de casser l'affichage et les applications :
- **toutes les applications et fonctionnalités UWP** — le pack n'y touche plus du tout : aucun `Remove-AppxPackage`, aucune opération DISM (`Remove-WindowsCapability`, `Disable-WindowsOptionalFeature`). Ce sont elles qui bloquaient de longues minutes.
- le **Microsoft Store**, **winget**, le **Panneau de configuration NVIDIA**
- **Microsoft Edge** — le pack n'y touche pas
- **NvContainer / NvCpl / HDAudio / PhysX** dans le pilote NVIDIA (audio HDMI/DP, panneau de configuration, vieux jeux PhysX)
- la **mise à l'échelle DPI** choisie par Windows (plus de forçage à 100 %)

## ⚠️ Avertissements importants
- **Sécurité désactivée** : Windows Defender (temps réel, cloud, tamper protection), UAC, BitLocker, SmartScreen, VBS/memory integrity sont désactivés. Le PC n'a plus de protection antivirus active. À réserver à une machine dédiée au gaming.
- **Mitigations CPU désactivées** : les protections Spectre / Meltdown / MDS sont coupées (`FeatureSettingsOverride=3`) pour récupérer quelques % de CPU. Pour revenir en arrière : supprimer `FeatureSettingsOverride` et `FeatureSettingsOverrideMask` dans `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`, puis redémarrer.
- **Irréversible en grande partie**. Le point de restauration créé à la fin ne couvre pas les changements déjà appliqués avant sa création.
- **Ne pas interrompre** les phases automatiques.
