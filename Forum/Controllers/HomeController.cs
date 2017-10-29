using Forum.Control;
using Forum.Models;
using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace Forum.Controllers
{
    public class HomeController : Controller
    {
        private Forum2017SQLEntities db = new Forum2017SQLEntities();
        private HttpCookie cookie { get; set; }

        private async Task<bool> PersonalArea()
        {
            cookie = Request.Cookies["ForumCookie"];

            if (cookie != null)
            {
                var UserId = Convert.ToInt64(cookie["UserId"]);
                var SecretKey = cookie["SecretKey"];
                var Password = cookie["Password"];

                if (UserId != null && SecretKey != null && Password == null)
                {
                    var skey = Crypto.Hash(SecretKey, "");
                    var cookieDB = db.Cookies.Where(p => p.UserId == UserId && p.SecretKey == skey);

                    if (await cookieDB.AnyAsync())
                    {
                        cookie.Expires = DateTime.Now.AddDays(30);
                        Response.Cookies.Add(cookie);

                        var dc = await db.Cookies.FirstOrDefaultAsync(p => p.UserId == UserId);
                        dc.DateOfExpiry = DateTime.Now.AddDays(30);
                        db.SaveChanges();

                        TempData["User"] = (await cookieDB.FirstOrDefaultAsync()).User;

                        return true;
                    }
                }
                else if (UserId != null && Password != null)
                {
                    var users = db.Users.Where(p => p.Id == UserId);
                    if (users.Any())
                    {
                        TempData["User"] = users.FirstOrDefault();
                        var pass = Convert.ToBase64String((TempData["User"] as User).Password);
                        if (pass == Password)
                        {
                            cookie.Expires = DateTime.Now.AddMinutes(10);
                            Response.Cookies.Add(cookie);
                            return true;
                        }
                    }
                }
            }

            if (TempData["User"] != null) TempData.Remove("User");
            return false;
        }

        public async Task<ActionResult> Index()
        {
            ViewBag.SignIn = await PersonalArea();
            ViewBag.Forums = await db.Fora.OrderBy(p => p.Topic).ToListAsync();
            
            return View();
        }

        public ActionResult Authorization()
        {
            return RedirectToAction("Index", "Home");
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Authorization(AuthorizationViewModel AuthorizationModel)
        {
            if (await db.Users.Where(p => p.Login == AuthorizationModel.Login).AnyAsync())
            {
                var user = await db.Users.FirstOrDefaultAsync(p => p.Login == AuthorizationModel.Login);
                var password = Crypto.Hash(AuthorizationModel.Password, user.Salt);

                if (user.Login == AuthorizationModel.Login && Convert.ToBase64String(user.Password) == Convert.ToBase64String(password))
                {
                    if (AuthorizationModel.RememberMe == true)
                    {
                        var IPv4 = IPaddress.GetIP();
                        var secretKey = System.Guid.NewGuid().ToString();

                        cookie = new HttpCookie("ForumCookie");
                        cookie["UserId"] = user.Id.ToString();
                        cookie["SecretKey"] = secretKey;
                        cookie.Expires = DateTime.Now.AddDays(30);

                        Response.Cookies.Add(cookie);

                        db.SetCookie(user.Nickname, IPv4, Crypto.Hash(secretKey, ""), DateTime.Now.AddDays(30));
                    }
                    else
                    {
                        HttpCookie cookie = new HttpCookie("ForumCookie");
                        cookie["UserId"] = user.Id.ToString();
                        cookie["Password"] = Convert.ToBase64String(user.Password);
                        cookie.Expires = DateTime.Now.AddMinutes(10);

                        Response.Cookies.Add(cookie);
                    }
                }
                else
                {
                    TempData["Alert"] = "Wrong login or password!!!";
                    return RedirectToAction("Index", "Home");
                }
            }
            else
            {
                TempData["Alert"] = "Wrong login or password!!!";
                return RedirectToAction("Index", "Home");
            }
            return RedirectToAction("Index", "Home");
        }

        public ActionResult Registration()
        {
            return RedirectToAction("Index", "Home");
        }
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<ActionResult> Registration(RegistrationViewModel RegistrationModel)
        {
            if (ModelState.IsValid)
            {
                var users = db.Users;

                if (await users.Where(p => p.Login == RegistrationModel.Login).AnyAsync())
                {
                    //ViewBag.Alert = "Login is already taken!";
                    ModelState.AddModelError("Login", "Login is already taken!");
                    return View(RegistrationModel);
                }
                if (await users.Where(p => p.Nickname == RegistrationModel.Nickname).AnyAsync())
                {
                    //ViewBag.Alert = "Nickname is already taken!";
                    ModelState.AddModelError("Nickname", "Nickname is already taken!");
                    return View(RegistrationModel);
                }

                var salt = System.Guid.NewGuid().ToString();
                var password = Crypto.Hash(RegistrationModel.PasswordConfirm, salt);

                db.Registration(RegistrationModel.Login, "", RegistrationModel.Nickname, password, salt, DateTime.Now);
                TempData["Alert"] = "Now authorize your account!";

                return RedirectToAction("Index", "Home");
            }
            return View(RegistrationModel);
        }

        public async Task<ActionResult> SignOut()
        {
            cookie = Request.Cookies["ForumCookie"];
            if (cookie != null)
            {
                var UserId = Convert.ToInt64(cookie["UserId"]);
                var SecretKey = cookie["SecretKey"];
                var skey = Crypto.Hash(SecretKey, IPaddress.GetIP());

                var c = db.Cookies.Where(p => p.UserId == UserId && p.SecretKey == skey);
                if (await c.AnyAsync())
                {
                    db.Cookies.RemoveRange(c);
                    await db.SaveChangesAsync();
                }

                cookie.Expires = DateTime.Now.AddDays(-1);
                Response.Cookies.Add(cookie);
            }

            if (TempData["User"] != null) TempData.Remove("User");
            return RedirectToAction("Index", "Home");
        }
    }
}