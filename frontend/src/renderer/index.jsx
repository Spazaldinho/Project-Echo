import React, { useState, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import sentencesData from '../../temp/sentences.json'; // AI generated sentences for the prototype

function App() {
  const sentences = sentencesData.sentences;
  const [sentence, setSentence] = useState(sentences[Math.floor(Math.random() * sentences.length)]);

  // screenshot capture functionality using Electron's desktopCapturer
  async function captureScreenshot() {
    try {
      const sources = await window.api.getDesktopSources();

      if (!sources || sources.length === 0) {
        console.error("No screen sources available");
        return;
      }

      const primarySource = sources[0];

      const stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          mandatory: {
            chromeMediaSource: 'desktop',
            chromeMediaSourceId: primarySource.id,
            minWidth: 1280,
            maxWidth: 1920,
            minHeight: 720,
            maxHeight: 1080
          }
        }
      });

      const video = document.createElement("video");
      video.srcObject = stream;
      await new Promise((resolve) => (video.onloadedmetadata = resolve));
      video.width = video.videoWidth;
      video.height = video.videoHeight;
      video.play();

      const canvas = document.createElement("canvas");
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const context = canvas.getContext("2d");
      context.drawImage(video, 0, 0, canvas.width, canvas.height);

      // stop the video stream
      stream.getTracks().forEach(track => track.stop());

      const timestamp = Date.now();
      const filename = `screenshot-${timestamp}.png`;

      // convert canvas to data URL
      const dataUrl = canvas.toDataURL('image/png');

      // save the image and get the file path
      const filepath = await window.api.saveImage(dataUrl, filename);

      // extract text from the saved screenshot using Tesseract
      const extractedText = await window.api.extractText(filepath);
      console.log('OCR Text:', extractedText);

      // delete the screenshot after extracting text
      await window.api.deleteFile(filepath);

    } catch (error) {
      console.error("Error capturing screenshot:", error);
    }
  }

  useEffect(() => {
    const intervalId = setInterval(() => {
      setSentence(sentences[Math.floor(Math.random() * sentences.length)]);
      captureScreenshot();
    }, 5000);

    return () => clearInterval(intervalId);
  }, []);

  return (
    <div style={{ padding: '20px' }}>
      <h1>Project Echo Prototype</h1>
      <p style={{ marginTop: '10px', fontSize: '18px' }}>{sentence}</p>
    </div>
  );
}

const root = createRoot(document.getElementById('root'));
root.render(<App />);
