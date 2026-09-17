# Video Downloader

Um aplicativo nativo para macOS que oferece uma interface limpa, moderna e intuitiva para baixar vídeos e áudios do YouTube (e centenas de outros sites) com máxima qualidade. Funciona como uma interface gráfica amigável para a poderosa ferramenta de linha de comando `yt-dlp`.

## 📥 Instalação

Você pode instalar o Video Downloader facilmente usando o Homebrew:

```bash
brew install carlosxfelipe/tap/video-downloader
```

## 📦 Dependências

Como o aplicativo executa os motores de download nativamente via terminal em background, você precisará ter algumas ferramentas instaladas no seu Mac. A própria interface do app possui um botão de ajuda guiando esse processo, mas em resumo você precisará de:

1. **[Homebrew](https://brew.sh/)**: O gerenciador de pacotes mais popular para macOS.
2. **[uv](https://astral.sh/uv)**: Um gerenciador e executor de ferramentas Python ultrarrápido (usado pelo app para executar o `yt-dlp` de forma isolada via `uvx`).
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```
3. **[FFmpeg](https://ffmpeg.org/)**: Essencial para converter arquivos para MP3 ou para mesclar as trilhas separadas de áudio e vídeo de alta resolução (1080p, 4K) fornecidas pelo YouTube.
   ```bash
   brew install ffmpeg
   ```

## 💻 Como rodar o projeto

1. Abra o projeto `VideoDownloader.xcodeproj` no Xcode.
2. Na aba **Signing & Capabilities** do target principal (`VideoDownloader`):
   - Adicione o seu **Development Team** (sua conta Apple ID).
   - Verifique se a opção **App Sandbox** foi removida (desativada). Sem isso, o macOS bloqueará a execução de comandos de terminal pelo App.
3. Selecione o seu Mac como destino de build.
4. Aperte **Run (⌘ + R)**.

## 🛠️ Tecnologias Utilizadas

- **SwiftUI**: Para a construção de toda a interface, seguindo as métricas e os padrões modernos de design da Apple (HIG).
- **Process (Foundation)**: Para a integração profunda com o shell (`/bin/zsh`), permitindo rodar e monitorar a saída do `yt-dlp` em tempo real sem travar a interface gráfica.
- **yt-dlp**: O motor de código aberto mais confiável do mundo para extração de vídeos na web.

## 📄 Licença

Este projeto está licenciado sob a [GNU General Public License v3.0](LICENSE).
