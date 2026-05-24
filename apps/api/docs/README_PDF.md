# How to get a PDF with flowcharts and DFDs

The file **ITR_Assignment_and_Status_Update_Journey.html** contains the full document with Mermaid diagrams. To get a PDF that includes all flowcharts and DFDs:

## Recommended: Browser → Print to PDF

1. **Open the HTML file in a browser**  
   Double-click `ITR_Assignment_and_Status_Update_Journey.html` or open it from Chrome/Edge/Firefox (e.g. `File → Open file`).

2. **Wait for diagrams to load**  
   Give it 2–3 seconds so Mermaid can load from the CDN and draw the flowcharts and DFDs. The blue box at the top will change to “Ready for PDF” when it’s safe to print.

3. **Save as PDF**  
   - Press **Ctrl+P** (Windows/Linux) or **Cmd+P** (Mac).  
   - Set destination to **Save as PDF** (or “Microsoft Print to PDF” / similar).  
   - Click **Save** and choose where to save the file.

The saved PDF will include all the rendered diagrams.

## If the HTML file doesn’t open (file://)

- **Option A:** Run a local server from the `api` folder, then open  
  `http://localhost:8000/docs/ITR_Assignment_and_Status_Update_Journey.html`  
  (e.g. `php -S localhost:8000` in the api folder).

- **Option B:** Use VS Code / Cursor “Live Preview” or “Open in Browser” on the HTML file.

Once the page loads in the browser, follow steps 2 and 3 above to save as PDF.
