#!/usr/bin/env python3
"""
Update missing i18n translations in Localizable.xcstrings.
This script adds missing English localizations and fixes 'new' state translations.
"""

import sys

from i18n_tools import (
    DEFAULT_KEEP_LANGUAGES,
    default_file_path,
    load_strings,
    print_update_summary,
    save_strings,
    update_missing_translations,
)

# Populate this map with explicit translations when introducing new keys.
# Format: {"Key": {"zh-Hans": "示例", "es": "Ejemplo"}}
NEW_STRINGS: dict[str, dict[str, str]] = {
    "App Icon": {
        "de": "App-Symbol",
        "es": "Icono de la app",
        "fr": "Icône de l’app",
        "ja": "Appアイコン",
        "ko": "앱 아이콘",
        "zh-Hans": "App 图标",
    },
    "Choose from Files": {
        "de": "Aus Dateien auswählen",
        "es": "Elegir de Archivos",
        "fr": "Choisir dans Fichiers",
        "ja": "ファイルから選択",
        "ko": "파일에서 선택",
        "zh-Hans": "从文件中选择",
    },
    "Choose from Photos": {
        "de": "Aus Fotos auswählen",
        "es": "Elegir de Fotos",
        "fr": "Choisir dans Photos",
        "ja": "写真から選択",
        "ko": "사진에서 선택",
        "zh-Hans": "从照片中选择",
    },
    "Choose how to set the icon.": {
        "de": "Wähle, wie das Icon gesetzt werden soll.",
        "es": "Elige cómo establecer el icono.",
        "fr": "Choisissez comment définir l’icône.",
        "ja": "アイコンの設定方法を選択してください。",
        "ko": "아이콘을 설정하는 방법을 선택하세요.",
        "zh-Hans": "选择设置图标的方式。",
    },
    "Edit Icon": {
        "de": "Icon bearbeiten",
        "es": "Editar icono",
        "fr": "Modifier l’icône",
        "ja": "アイコンを編集",
        "ko": "아이콘 편집",
        "zh-Hans": "编辑图标",
    },
    "Failed to encode icon image.": {
        "de": "Icon-Bild konnte nicht kodiert werden.",
        "es": "No se pudo codificar la imagen del icono.",
        "fr": "Impossible d’encoder l’image de l’icône.",
        "ja": "アイコン画像のエンコードに失敗しました。",
        "ko": "아이콘 이미지를 인코딩하지 못했습니다.",
        "zh-Hans": "无法编码图标图片。",
    },
    "Failed to load the selected image.": {
        "de": "Das ausgewählte Bild konnte nicht geladen werden.",
        "es": "No se pudo cargar la imagen seleccionada.",
        "fr": "Impossible de charger l’image sélectionnée.",
        "ja": "選択した画像を読み込めませんでした。",
        "ko": "선택한 이미지를 불러오지 못했습니다.",
        "zh-Hans": "无法加载所选图片。",
    },
    "Fetch": {
        "de": "Abrufen",
        "es": "Obtener",
        "fr": "Récupérer",
        "ja": "取得",
        "ko": "가져오기",
        "zh-Hans": "获取",
    },
    "Fetch App Store Icon": {
        "de": "App Store-Icon abrufen",
        "es": "Obtener icono de App Store",
        "fr": "Récupérer l’icône de l’App Store",
        "ja": "App Storeのアイコンを取得",
        "ko": "App Store 아이콘 가져오기",
        "zh-Hans": "获取 App Store 图标",
    },
    "Get Icon from URL": {
        "de": "Icon aus URL holen",
        "es": "Obtener icono desde URL",
        "fr": "Obtenir l’icône depuis une URL",
        "ja": "URLからアイコンを取得",
        "ko": "URL에서 아이콘 가져오기",
        "zh-Hans": "从 URL 获取图标",
    },
    "No App Store artwork URL was returned.": {
        "de": "Es wurde keine App Store-Artwork-URL zurückgegeben.",
        "es": "No se devolvió ninguna URL de imagen del App Store.",
        "fr": "Aucune URL d’illustration App Store n’a été renvoyée.",
        "ja": "App StoreのアートワークURLが返されませんでした。",
        "ko": "App Store 아트워크 URL이 반환되지 않았습니다.",
        "zh-Hans": "未返回 App Store 图稿 URL。",
    },
    "No App Store results found for that app id.": {
        "de": "Keine App Store-Ergebnisse für diese App-ID gefunden.",
        "es": "No se encontraron resultados en el App Store para ese ID de app.",
        "fr": "Aucun résultat App Store trouvé pour cet identifiant d’app.",
        "ja": "そのApp IDのApp Store結果が見つかりませんでした。",
        "ko": "해당 앱 ID에 대한 App Store 결과를 찾을 수 없습니다.",
        "zh-Hans": "未找到该 App ID 的 App Store 结果。",
    },
    "No subscription icon": {
        "de": "Kein Abonnement-Symbol",
        "es": "Sin icono de suscripción",
        "fr": "Aucune icône d’abonnement",
        "ja": "サブスクリプションのアイコンなし",
        "ko": "구독 아이콘 없음",
        "zh-Hans": "无订阅图标",
    },
    "Only https URLs are supported.": {
        "de": "Nur https-URLs werden unterstützt.",
        "es": "Solo se admiten URLs https.",
        "fr": "Seules les URL https sont prises en charge.",
        "ja": "https のURLのみ対応しています。",
        "ko": "https URL만 지원됩니다.",
        "zh-Hans": "仅支持 https URL。",
    },
    "Paste an App Store link or enter an app id.": {
        "de": "Füge einen App Store-Link ein oder gib eine App-ID ein.",
        "es": "Pega un enlace del App Store o introduce un ID de app.",
        "fr": "Collez un lien App Store ou saisissez un identifiant d’app.",
        "ja": "App Storeのリンクを貼り付けるか、App IDを入力してください。",
        "ko": "App Store 링크를 붙여넣거나 앱 ID를 입력하세요.",
        "zh-Hans": "粘贴 App Store 链接或输入 App ID。",
    },
    "Paste an https image URL.": {
        "de": "Füge eine https-Bild-URL ein.",
        "es": "Pega una URL de imagen https.",
        "fr": "Collez une URL d’image https.",
        "ja": "https の画像URLを貼り付けてください。",
        "ko": "https 이미지 URL을 붙여넣으세요.",
        "zh-Hans": "粘贴 https 图片 URL。",
    },
    "Paste a website URL or an https image URL.": {
        "de": "Füge eine Website-URL oder eine https-Bild-URL ein.",
        "es": "Pega una URL de sitio web o una URL de imagen https.",
        "fr": "Collez une URL de site web ou une URL d’image https.",
        "ja": "WebサイトのURLまたは https の画像URLを貼り付けてください。",
        "ko": "웹사이트 URL 또는 https 이미지 URL을 붙여넣으세요.",
        "zh-Hans": "粘贴网站 URL 或 https 图片 URL。",
    },
    "Please enter a valid App Store link or app id.": {
        "de": "Bitte gib einen gültigen App Store-Link oder eine App-ID ein.",
        "es": "Introduce un enlace del App Store o un ID de app válido.",
        "fr": "Veuillez saisir un lien App Store ou un identifiant d’app valide.",
        "ja": "有効なApp StoreリンクまたはApp IDを入力してください。",
        "ko": "유효한 App Store 링크 또는 앱 ID를 입력하세요.",
        "zh-Hans": "请输入有效的 App Store 链接或 App ID。",
    },
    "Please enter a valid URL.": {
        "de": "Bitte gib eine gültige URL ein.",
        "es": "Introduce una URL válida.",
        "fr": "Veuillez saisir une URL valide.",
        "ja": "有効なURLを入力してください。",
        "ko": "유효한 URL을 입력하세요.",
        "zh-Hans": "请输入有效的 URL。",
    },
    "Remove Icon": {
        "de": "Icon entfernen",
        "es": "Eliminar icono",
        "fr": "Supprimer l’icône",
        "ja": "アイコンを削除",
        "ko": "아이콘 제거",
        "zh-Hans": "移除图标",
    },
    "Request failed with status code %lld.": {
        "de": "Anfrage fehlgeschlagen (Statuscode %lld).",
        "es": "La solicitud falló con el código de estado %lld.",
        "fr": "La requête a échoué avec le code d’état %lld.",
        "ja": "リクエストに失敗しました（ステータスコード %lld）。",
        "ko": "요청에 실패했습니다(상태 코드 %lld).",
        "zh-Hans": "请求失败，状态码 %lld。",
    },
    "Subscription icon": {
        "de": "Abonnement-Symbol",
        "es": "Icono de suscripción",
        "fr": "Icône d’abonnement",
        "ja": "サブスクリプションのアイコン",
        "ko": "구독 아이콘",
        "zh-Hans": "订阅图标",
    },
    "The downloaded data is not a valid image.": {
        "de": "Die heruntergeladenen Daten sind kein gültiges Bild.",
        "es": "Los datos descargados no son una imagen válida.",
        "fr": "Les données téléchargées ne sont pas une image valide.",
        "ja": "ダウンロードしたデータは有効な画像ではありません。",
        "ko": "다운로드한 데이터가 유효한 이미지가 아닙니다.",
        "zh-Hans": "下载的数据不是有效的图片。",
    },
    "The image is too large (max %lld bytes).": {
        "de": "Das Bild ist zu groß (max. %lld Bytes).",
        "es": "La imagen es demasiado grande (máx. %lld bytes).",
        "fr": "L’image est trop grande (max. %lld octets).",
        "ja": "画像が大きすぎます（最大 %lld バイト）。",
        "ko": "이미지가 너무 큽니다(최대 %lld바이트).",
        "zh-Hans": "图片太大（最大 %lld 字节）。",
    },
    "The server returned an invalid response.": {
        "de": "Der Server hat eine ungültige Antwort zurückgegeben.",
        "es": "El servidor devolvió una respuesta no válida.",
        "fr": "Le serveur a renvoyé une réponse invalide.",
        "ja": "サーバーが無効な応答を返しました。",
        "ko": "서버가 유효하지 않은 응답을 반환했습니다.",
        "zh-Hans": "服务器返回了无效的响应。",
    },
    "https://apps.apple.com/... or 123456789": {
        "de": "https://apps.apple.com/... oder 123456789",
        "es": "https://apps.apple.com/... o 123456789",
        "fr": "https://apps.apple.com/... ou 123456789",
        "ja": "https://apps.apple.com/... または 123456789",
        "ko": "https://apps.apple.com/... 또는 123456789",
        "zh-Hans": "https://apps.apple.com/... 或 123456789",
    },
    "https://example.com/icon.png": {
        "de": "https://example.com/icon.png",
        "es": "https://example.com/icon.png",
        "fr": "https://example.com/icon.png",
        "ja": "https://example.com/icon.png",
        "ko": "https://example.com/icon.png",
        "zh-Hans": "https://example.com/icon.png",
    },
}

if __name__ == "__main__":
    file_path = sys.argv[1] if len(sys.argv) > 1 else default_file_path()

    data = load_strings(file_path)
    counts = update_missing_translations(
        data,
        new_strings=NEW_STRINGS,
        keep_languages=DEFAULT_KEEP_LANGUAGES,
    )
    save_strings(file_path, data)

    print_update_summary(file_path, counts)
