-- Enable pgcrypto extension for cryptographic functions
-- This provides gen_random_bytes() and digest() functions

-- Enable the pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Verify the extension is working by testing gen_random_bytes
DO $$
BEGIN
    -- Test that gen_random_bytes is available
    PERFORM gen_random_bytes(16);
    RAISE NOTICE '✅ pgcrypto extension enabled successfully - gen_random_bytes is available';
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '❌ Failed to enable pgcrypto extension: %', SQLERRM;
END $$; 