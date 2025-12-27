import sharp from 'sharp';

const sizes = [192, 512];

const svgBuffer = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1e3a8a"/>
      <stop offset="100%" style="stop-color:#1e40af"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" fill="url(#bg)" rx="80"/>
  <circle cx="256" cy="200" r="80" fill="#fbbf24"/>
  <rect x="156" y="260" width="200" height="140" fill="white" rx="20"/>
  <rect x="180" y="290" width="60" height="40" fill="#10b981" rx="8"/>
  <rect x="272" y="290" width="60" height="40" fill="#3b82f6" rx="8"/>
  <rect x="180" y="350" width="152" height="30" fill="#e5e7eb" rx="6"/>
  <rect x="206" y="180" width="100" height="50" fill="#dc2626" rx="10"/>
  <text x="256" y="215" font-size="32" font-weight="bold" text-anchor="middle" fill="white" font-family="Arial">BÁN</text>
</svg>`;

for (const size of sizes) {
  await sharp(Buffer.from(svgBuffer))
    .resize(size, size)
    .png()
    .toFile(`public/icon-${size}x${size}.png`);
  console.log(`Created icon-${size}x${size}.png`);
}
