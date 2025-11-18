const { app, BrowserWindow, ipcMain, desktopCapturer } = require('electron');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    show: true, // display the electron window
    webPreferences: {
      preload: path.join(__dirname, '../preload/index.js'),
      nodeIntegration: false,
      contextIsolation: true,
    }
  });

  if (process.env.ELECTRON_RENDERER_URL) {
    mainWindow.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  }

  // open DevTools in development
  if (!app.isPackaged) {
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', function () {
    mainWindow = null;
    process.exit(0);
  });
}

ipcMain.handle('get-desktop-sources', async () => {
  const sources = await desktopCapturer.getSources({
    types: ['screen'],
    thumbnailSize: { width: 1920, height: 1080 }
  });
  return sources;
});

// get image from data URL
ipcMain.handle('save-image', async (event, dataUrl, filename) => {
  try {
    const backendPath = path.join(__dirname, '../../../backend');
    const tempDir = path.join(backendPath, 'temp');

    // temp directory if it doesn't exist
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    const filepath = path.join(tempDir, filename);
    const base64Data = dataUrl.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');

    fs.writeFileSync(filepath, buffer);

    return filepath;
  } catch (error) {
    throw new Error(`Failed to save image: ${error.message}`);
  }
});

// tesseract OCR handler
ipcMain.handle('ocr-extract-text', async (event, imagePath) => {
  return new Promise((resolve, reject) => {
    const backendPath = path.join(__dirname, '../../../backend');
    const pythonPath = path.join(backendPath, 'venv/bin/python3');
    const scriptPath = path.join(backendPath, 'tesseract.py');

    const python = spawn(pythonPath, [scriptPath, imagePath], {
      cwd: backendPath
    });

    let result = '';
    let error = '';

    python.stdout.on('data', (data) => {
      result += data.toString();
    });

    python.stderr.on('data', (data) => {
      error += data.toString();
    });

    python.on('close', (code) => {
      if (code === 0) {
        resolve(result.trim());
      } else {
        reject(new Error(`Python script failed: ${error}`));
      }
    });

    python.on('error', (err) => {
      reject(new Error(`Failed to start Python process: ${err.message}`));
    });
  });
});

// delete file handler
ipcMain.handle('delete-file', async (event, filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      return { success: true };
    }
    return { success: false, error: 'File not found' };
  } catch (error) {
    throw new Error(`Failed to delete file: ${error.message}`);
  }
});

// save scraped info to database
ipcMain.handle('save-scraped-info', async (event, description, imagePath) => {
  const backendPath = path.join(__dirname, '../../../backend');
  const srcDatabasePath = path.join(backendPath, 'src/database.js');
  const prisma = require(srcDatabasePath);
  const scrapedInfo = await prisma.scrapedInfo.create({
    data: {
      description,
      imagePath,
    }
  });
  return scrapedInfo;
});

app.whenReady().then(createWindow);

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') {
    app.quit();
    process.exit(0);
  }
});

app.on('activate', function () {
  if (mainWindow === null) {
    createWindow();
  }
});