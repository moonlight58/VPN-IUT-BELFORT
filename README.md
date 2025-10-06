# VPN-IUT-BELFORT

Scripts permettant aux étudiants de l'IUT de Belfort-Montbéliard de configurer rapidement le VPN de l'Université de Franche-Comté (uFC) sur Windows et Linux.

## Contenu du projet

- **Init-VPN-Window.ps1** : Script PowerShell pour configurer le VPN sur Windows.
- **Init-VPN-Linux.sh** : Script Bash pour configurer le VPN sur les distributions Linux compatibles.

## Instructions d'installation

### Window

```powershell
git clone https://github.com/moonlight58/VPN-IUT-BELFORT.git
cd .\VPN-IUT-BELFORT\
.\init-VPN-Window.ps1
```

### Linux

```bash
git clone https://github.com/moonlight58/VPN-IUT-BELFORT.git
cd VPN-IUT-BELFORT/
chmod +x init-VPN-Linux.sh
./init-VPN-Linux.sh
```

## Notes importantes
- L'adresse du serveur VPN est configurée par défaut sur vpn20-2.univ-fcomte.fr. Si cette adresse change, veuillez consulter le [site officiel du VPN de l'uFC](https://vpn.univ-fcomte.fr/?page_id=254).
- La MTU est configurée à 1300 pour éviter les problèmes de fragmentation.
- Les scripts Linux incluent un support spécifique pour les stations d'accueil Dell.

## Avertissement
Ces scripts sont fournis "tels quels". Veuillez les utiliser avec précaution et vérifier leur contenu avant exécution.

## Licence
Ce projet est sous licence MIT.