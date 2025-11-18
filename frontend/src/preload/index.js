const { contextBridge, ipcRenderer } = require('electron');

// expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('api', {
  // screen capture API
  getDesktopSources: () => ipcRenderer.invoke('get-desktop-sources'),

  // image saving API
  saveImage: (dataUrl, filename) => ipcRenderer.invoke('save-image', dataUrl, filename),

  // tesseract OCR API
  extractText: (imagePath) => ipcRenderer.invoke('ocr-extract-text', imagePath),

  // file deletion API
  deleteFile: (filePath) => ipcRenderer.invoke('delete-file', filePath),

  // scraped info
  saveScrapedInfo: (description, imagePath) => ipcRenderer.invoke('save-scraped-info', description, imagePath),
});
