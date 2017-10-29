using Forum.Control;
using Forum.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace Forum.Controllers
{
    public class ForumController : Controller
    {
        private Forum2017SQLEntities db = new Forum2017SQLEntities();
        private HttpCookie cookie { get; set; }

        public async Task<ActionResult> Index(string Topic)
        {
            var forum = db.Fora.FirstOrDefault(p => p.CodeForum == Topic);
            ViewBag.Forum = forum;
            if (string.IsNullOrEmpty(Topic) ||
                await PersonalArea() == false ||
                ViewBag.Forum == null)
                return RedirectToAction("Index", "Home");

            var notifications = forum.Messages.Where(p => p.Notifications.Any());
            if(notifications.Any() && forum.User.Nickname == (TempData["User"] as User).Nickname)
            {
                foreach (var item in notifications)
                {
                    db.Notifications.RemoveRange(item.Notifications);
                    await db.SaveChangesAsync();
                }
            }

            return View();
        }

        public async Task<ActionResult> NewForum(string topic)
        {
            if (await PersonalArea() == false) return RedirectToAction("Index", "Home");
            if (string.IsNullOrEmpty(topic))
            {
                TempData["Alert"] = "The new forum field is required";
                return RedirectToAction("Index", "Home");
            }
            var User = TempData["User"] as User;

            string code = System.Guid.NewGuid().ToString();
            while (await db.Fora.Where(p => p.CodeForum == code).AnyAsync())
                code = System.Guid.NewGuid().ToString();

            if (await db.Fora.Where(p => p.Topic == topic).AnyAsync())
                return RedirectToAction("Index", "Forum", new { Topic = db.Fora.FirstOrDefault(p => p.Topic == topic).CodeForum });
            else
                db.NewForum(code, topic, User.Nickname, DateTime.Now.AddHours(3));

            return RedirectToAction("Index", "Forum", new { Topic = code });
        }

        [HttpPost]
        [ValidateInput(false)]
        public async Task<ActionResult> NewMessage(string topic, string newtext)
        {
            if (await PersonalArea() == false || string.IsNullOrEmpty(topic)) return RedirectToAction("Index", "Home");
            if (!string.IsNullOrEmpty(newtext))
            {
                var forum = await db.Fora.FirstOrDefaultAsync(p => p.CodeForum == topic);
                db.NewMessage(forum.Id, (TempData["User"] as User).Nickname, newtext, DateTime.Now.AddHours(3));//DateTime.Now
            }
            else TempData["Alert"] = "The new message field is required";

            return RedirectToAction("Index", "Forum", new { Topic = topic });
        }

        [HttpPost]
        [ValidateInput(false)]
        public async Task<ActionResult> EditMessage(string topic, long MessageId, string edittext)
        {
            if (await PersonalArea() == false || string.IsNullOrEmpty(topic)) return RedirectToAction("Index", "Home");

            if (MessageId != null && !string.IsNullOrEmpty(edittext))
            {
                var m = await db.Messages.FirstOrDefaultAsync(p => p.Id == MessageId);

                if ((TempData["User"] as User) != m.User)
                {
                    TempData["Alert"] = "It is forbidden to edit the message!";
                    return RedirectToAction("Index", "Forum", new { Topic = topic });
                }
                if(m.Message1 != edittext)
                    db.EditingMessage(MessageId, 0, edittext, DateTime.Now.AddHours(3), m.Message1);
            }
            else TempData["Alert"] = "The message field must not be empty";

            return RedirectToAction("Index", "Forum", new { Topic = topic });
        }

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
    }
}