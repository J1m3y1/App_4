const { customAlphabet } = require('nanoid');

// Excludes visually ambiguous characters (0/O, 1/I).
const ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
const CODE_LENGTH = 6;
const MAX_ATTEMPTS = 20;

const generate = customAlphabet(ALPHABET, CODE_LENGTH);

function generateRoomCode(isTaken) {
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const code = generate();
    if (!isTaken(code)) return code;
  }
  throw new Error('Could not generate a unique room code');
}

module.exports = { generateRoomCode };
