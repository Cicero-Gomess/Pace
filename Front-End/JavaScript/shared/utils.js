export function escaparHTML(valor) {
  return String(valor ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

export function formatarDataRelativa(dataISO) {
  if (!dataISO) return "";

  const data = new Date(dataISO);
  if (Number.isNaN(data.getTime())) return "";

  const agora = new Date();
  const diferenca = agora - data;
  const segundos = Math.floor(diferenca / 1000);
  const minutos = Math.floor(segundos / 60);
  const horas = Math.floor(minutos / 60);
  const dias = Math.floor(horas / 24);
  const semanas = Math.floor(dias / 7);
  const meses = Math.floor(dias / 30);
  const anos = Math.floor(dias / 365);

  if (segundos < 60) return "há poucos segundos";
  if (minutos < 60) return `há ${minutos} minuto${minutos === 1 ? "" : "s"}`;
  if (horas < 24) return `há ${horas} hora${horas === 1 ? "" : "s"}`;
  if (dias < 7) return `há ${dias} dia${dias === 1 ? "" : "s"}`;
  if (semanas < 5) return `há ${semanas} semana${semanas === 1 ? "" : "s"}`;
  if (meses < 12) return `há ${meses} mês${meses === 1 ? "" : "es"}`;
  return `há ${anos} ano${anos === 1 ? "" : "s"}`;
}

export function formatarDataCurta(dataISO) {
  if (!dataISO) return "";

  const data = new Date(dataISO);
  if (Number.isNaN(data.getTime())) return "";

  return data.toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

export function normalizarTexto(texto) {
  return texto.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

export async function compactarImagem(file, maxWidth = 1280, quality = 0.82) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      const img = new Image();

      img.onload = () => {
        const canvas = document.createElement("canvas");
        const scale = Math.min(1, maxWidth / img.width);

        canvas.width = Math.round(img.width * scale);
        canvas.height = Math.round(img.height * scale);

        const ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        resolve(canvas.toDataURL("image/jpeg", quality));
      };

      img.onerror = () => reject(new Error("Erro ao processar imagem."));
      img.src = reader.result;
    };

    reader.onerror = () => reject(new Error("Erro ao ler arquivo."));
    reader.readAsDataURL(file);
  });
}
