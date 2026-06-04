import { initAppShell } from "./shared/app-shell.js";
import { getCurrentUser } from "./shared/auth.js";
import { createPost } from "./shared/services/post-service.js";
import { handleAuthError } from "./shared/auth.js";
import { initLucide, syncProfilePhotos } from "./shared/ui.js";
import { compactarImagem } from "./shared/utils.js";
import { resolveUserPhoto } from "./shared/users-cache.js";
import { ApiError } from "./shared/api.js";

const shellOk = await initAppShell();
if (shellOk) {
  initLucide();
  syncProfilePhotos();

  const user = getCurrentUser();
  const nomeAutor = document.getElementById("nomeAutor");
  const fotoAutor = document.getElementById("fotoAutor");

  if (nomeAutor && user) nomeAutor.innerText = user.username || "Usuário";
  if (fotoAutor && user) fotoAutor.src = resolveUserPhoto(user);

  const btn = document.getElementById("btnPostar");
  const textarea = document.getElementById("textoPost");
  const contador = document.getElementById("contador");
  const fileInput = document.getElementById("imagemPost");
  const previewBox = document.getElementById("previewImagem");
  const imgPreview = document.getElementById("imgPreview");
  const nomeImagem = document.getElementById("nomeImagem");
  const removerBtn = document.getElementById("removerImagem");
  const chips = document.querySelectorAll(".inspira-chip");

  if (textarea && contador) {
    textarea.addEventListener("input", () => {
      contador.innerText = `${textarea.value.length}/200`;
    });
  }

  chips.forEach((chip) => {
    chip.addEventListener("click", () => {
      if (!textarea.value.trim()) {
        textarea.value = chip.dataset.texto;
      } else {
        textarea.value = `${textarea.value.trim()} ${chip.dataset.texto}`;
      }
      textarea.dispatchEvent(new Event("input"));
      textarea.focus();
    });
  });

  fileInput?.addEventListener("change", () => {
    const file = fileInput.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      imgPreview.src = reader.result;
      nomeImagem.innerText = file.name;
      previewBox.classList.remove("hidden");
    };
    reader.readAsDataURL(file);
  });

  removerBtn?.addEventListener("click", () => {
    fileInput.value = "";
    previewBox.classList.add("hidden");
    imgPreview.src = "";
    nomeImagem.innerText = "";
  });

  function resetButton() {
    btn.disabled = false;
    btn.innerHTML = `
      <i data-lucide="send"></i>
      <span>Publicar agora</span>
    `;
    lucide.createIcons();
  }

  btn?.addEventListener("click", async () => {
    const texto = textarea.value.trim();
    const file = fileInput.files[0];

    if (!texto && !file) {
      alert("Escreva algo ou selecione uma imagem!");
      return;
    }

    btn.disabled = true;
    btn.innerHTML = `
      <i data-lucide="loader-circle"></i>
      <span>Publicando...</span>
    `;
    lucide.createIcons();

    try {
      let imagemBase64 = null;
      if (file) {
        imagemBase64 = await compactarImagem(file);
      }

      await createPost(texto, imagemBase64);
      window.location.href = "feed.html";
    } catch (error) {
      resetButton();
      if (handleAuthError(error)) return;
      alert(error instanceof ApiError ? error.message : "Erro ao publicar.");
    }
  });
}
