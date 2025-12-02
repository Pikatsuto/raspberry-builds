# Documentation Troubleshooting Guide

## Site déployé à la racine au lieu de `/raspberry-builds/`

Si votre site GitHub Pages est accessible sur `https://pikatsuto.github.io/` au lieu de `https://pikatsuto.github.io/raspberry-builds/`, voici comment résoudre le problème :

### Vérifier la configuration GitHub Pages

1. Allez dans **Settings** → **Pages** du repository
2. Vérifiez la section **Source**
3. Assurez-vous que :
   - Source = **GitHub Actions** (PAS "Deploy from a branch")
   - Custom domain = vide (sauf si vous utilisez un domaine personnalisé)

### Si vous voulez déployer à la racine

Si vous préférez que le site soit à `https://pikatsuto.github.io/` :

1. Renommez le repository en `pikatsuto.github.io`
2. Modifiez `docs/nuxt.config.ts` :
   ```typescript
   app: {
     baseURL: '/', // Changé de '/raspberry-builds/'
   ```

3. Modifiez `docs/.github/workflows/deploy-docs.yml` si nécessaire

### Si vous voulez garder `/raspberry-builds/`

C'est déjà la configuration par défaut. Assurez-vous que :

1. Le repository s'appelle bien `raspberry-builds` (pas `pikatsuto.github.io`)
2. GitHub Pages Source = **GitHub Actions**
3. Le `baseURL` dans `nuxt.config.ts` est : `'/raspberry-builds/'`

### Test en local

Le baseURL est conditionnel selon l'environnement :

**En développement local :**
```bash
npm run dev
# Site accessible sur http://localhost:3000/ (racine)
```

**En production (après build) :**
```bash
npm run generate
# Fichiers dans dist/ avec liens pointant vers /raspberry-builds/...
```

Pour tester le build de production localement avec le baseURL :

```bash
npm run generate
cd ../dist
python3 -m http.server 8000
# Visitez http://localhost:8000/raspberry-builds/ (notez le sous-dossier!)
```

### Structure des fichiers après build

Il est **normal** que les fichiers soient dans `dist/` à la racine :

```
dist/
├── index.html
├── releases/
│   └── index.html
├── _nuxt/
└── ...
```

Le `baseURL` affecte seulement les **liens à l'intérieur des fichiers HTML**, pas la structure des dossiers.

Par exemple, dans `dist/index.html` :
```html
<!-- Liens internes pointent vers /raspberry-builds/ -->
<a href="/raspberry-builds/releases">Releases</a>

<!-- Assets pointent vers /raspberry-builds/_nuxt/ -->
<script src="/raspberry-builds/_nuxt/entry.js"></script>
```

GitHub Pages sait servir ces fichiers depuis `/raspberry-builds/` grâce à sa configuration.

## Erreurs courantes

### 404 sur toutes les pages sauf l'accueil

**Cause :** baseURL incorrect ou GitHub Pages mal configuré

**Solution :**
1. Vérifiez `app.baseURL` dans `nuxt.config.ts`
2. Vérifiez que GitHub Pages Source = **GitHub Actions**

### Assets (CSS/JS) ne chargent pas

**Cause :** baseURL ne correspond pas au chemin de déploiement

**Solution :**
1. Vérifiez les URLs dans le HTML généré (regardez dans `dist/index.html`)
2. Assurez-vous que le `baseURL` correspond au chemin réel du site

### Liens de navigation cassés

**Cause :** Liens en dur dans le code sans utiliser le composant NuxtLink

**Solution :**
- Utilisez toujours `<NuxtLink to="/path">` au lieu de `<a href="/path">`
- Les chemins commencent par `/` (relatifs à la racine) : `to="/docs/page"`

## Variables d'environnement

La configuration utilise `NODE_ENV` pour déterminer le baseURL :

- **Development** (`npm run dev`) : `baseURL = '/'`
- **Production** (`npm run generate`) : `baseURL = '/raspberry-builds/'`

Vous pouvez tester en production localement :

```bash
NODE_ENV=production npm run generate
```

## Besoin d'aide ?

Si le problème persiste :

1. Vérifiez les logs GitHub Actions (tab **Actions**)
2. Inspectez le HTML généré dans `dist/`
3. Vérifiez l'URL complète du site déployé dans **Settings** → **Pages**
4. Ouvrez une issue sur le repository