import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { detectAndApplyPlatform } from "./lib/detectPlatform";

import "./styles/tokens.css";
import "./styles/animations.css";
import "./styles/os-windows.css";
import "./styles/os-macos.css";
import "./styles/os-linux-gnome.css";
import "./styles/os-linux-kde.css";

async function bootstrap() {
  await detectAndApplyPlatform();

  ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  );
}

bootstrap();
