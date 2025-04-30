import pkg from '../package.json';
import fs from 'fs';

fs.writeFileSync('version.lua', `return '${pkg.version}'`)