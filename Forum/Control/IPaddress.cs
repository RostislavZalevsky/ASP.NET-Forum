namespace Forum.Control
{
    public static class IPaddress
    {
        public static string GetIP()
        {
            System.Web.HttpContext context = System.Web.HttpContext.Current;
            string ipAddress = context.Request.ServerVariables["HTTP_X_FORWARDED_FOR"];

            if (!string.IsNullOrEmpty(ipAddress))
            {
                string[] addresses = ipAddress.Split(',');
                if (addresses.Length != 0)
                {
                    string[] IPv4 = addresses[0].Split(':');
                    if(IPv4.Length != 0)
                    {
                        return IPv4[0];
                    }
                }
            }

            return context.Request.ServerVariables["REMOTE_ADDR"];
        }

    }
}