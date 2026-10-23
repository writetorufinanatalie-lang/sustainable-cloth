# Loomtrace — apparel sustainability evidence checker

Loomtrace reviews a public apparel product page, researches the listed materials, and presents an evidence-confidence score with sources. It can suggest similar products when confidence is low and the search finds a specific, independently supported sustainability advantage. There is no seeded product or product database.

## Run it

Open `index.html` in a browser for the static interface, or publish it with GitHub Pages. The product analyzer and certificate workbench require the server-side Vercel Functions in `api/`; they do not run from a local file or GitHub Pages alone.

## Evidence review workbench

The reviewer selects a text-based certificate PDF. PDF.js extracts text in the browser. Selecting a file does not upload it. When the reviewer explicitly clicks **Analyze with AI**, the extracted text and comparison fields are sent to `/api/review`; the PDF itself is not sent. The server calls the OpenAI Responses API with a strict JSON Schema and returns short findings with quotes and page numbers. The model can flag missing fields, apparent date/scope mismatches, and conflicts with the comparison record.

The endpoint does not access issuer registries and cannot authenticate a certificate, verify a real supply chain, or certify a product. The reviewer must inspect the original, verify the issuer in its official registry, confirm facility and transaction scope, and make the final decision. Scanned PDFs need OCR and are not extracted here. No certificate or review is stored by this prototype. Do not add the API key to HTML, JavaScript, GitHub, or any other client-side file.

## Product-link material analysis

On the front page, paste a public apparel product-page URL and click **Analyze materials**. The server uses live web search to look for the listed composition, material research, product-specific impact evidence, certifications/traceability, and repair or end-of-life details. It displays an **evidence confidence score**, not an eco score. The score is a transparent completeness heuristic: product listing cited (10), materials identified (15), percentages total 100% (10), independent material research cited (20), product-specific impact data found (20), supply-chain/certification evidence found (15), and repair/end-of-life information found (10). These checks are based on AI-extracted fields and cited search results, so the score is a triage aid, not independent verification.

If the score is below 60, the analyzer searches for up to three similar products. It only displays a candidate when both its product page and at least one separate source supporting its named sustainability advantage are in the search results; both are linked on the card. If evidence is weak, that means “unknown,” not “bad”; a recommendation must state its tradeoff and is not a guarantee of lower total impact. No alternatives are shown if the search cannot substantiate any. The score breakdown links the sources supporting each awarded evidence category. The user sends the URL to the AI service only by clicking the analysis button. If a shop blocks indexing or omits composition details, the result should say it cannot assess the product specifically.

## Enable AI review on Vercel

1. Import this repository into Vercel using the repository root. Vercel detects the root `api/` directory and deploys `api/product.mjs` and `api/review.mjs` as Node.js Functions.
2. In the Vercel project, open **Settings → Environment Variables** and add `OPENAI_API_KEY` with a project API key. Product analysis uses `OPENAI_WEB_MODEL` (default `gpt-5.5`, which supports Responses web search); certificate review uses `OPENAI_MODEL` (default `gpt-4o-mini`). Set either variable to a model available to that API key if needed.
3. Redeploy. Use the Vercel deployment to analyze a public product URL or visit `/review.html` to review a certificate. A local `file://` page or GitHub Pages copy cannot reach these server routes.

The API routes apply small per-IP in-memory request limits. Those limits are best-effort on a serverless deployment; before a widely used public launch, add durable rate limiting or access control and monitor model usage. Product analysis uses OpenAI's hosted web search and shows clickable source links returned with the answer. See [OpenAI Web Search](https://developers.openai.com/api/docs/guides/tools-web-search), [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=responses), and [Vercel Node.js Functions](https://vercel.com/docs/functions/runtimes/node-js).

## Source and claim rules

The analyzer depends on public pages being searchable and may not be able to assess listings that block indexing or omit composition. It does not independently authenticate certificates, verify a real supply chain, or calculate the garment's full environmental footprint. Treat its score as a completeness heuristic and recommendations as leads to investigate, not guarantees of lower impact.
