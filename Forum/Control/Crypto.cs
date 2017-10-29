using System.Text;

namespace Forum.Control
{
    public static class Crypto
    {
        public static byte[] Hash(string input, string salt)
        {
            return System.Security.Cryptography.SHA512Managed.Create()
               .ComputeHash(Encoding.UTF8.GetBytes(string.Concat(input, salt)));
        }
    }
}