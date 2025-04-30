import pkg from '../package.json' with { type: 'json' };
import fs from 'fs';

fs.writeFileSync('version.lua', `return '${pkg.version}'`)