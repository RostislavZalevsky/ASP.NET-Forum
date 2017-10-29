using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace Forum.Models
{
    public class AuthorizationViewModel
    {
        [Required]
        [DataType(DataType.Text)]
        [Display(Name = "Login")]
        public string Login { get; set; }

        [Required]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; }

        [Display(Name = "Remember me")]
        [DefaultValue(true)]
        public bool RememberMe { get; set; }
    }

    public class RegistrationViewModel
    {
        [Required]
        [StringLength(50, MinimumLength = 3, ErrorMessage = "The length of the string must be between 3 and 50 characters")]
        [Display(Name = "Login")]
        public string Login { get; set; }

        [Required]
        [StringLength(50, MinimumLength = 3, ErrorMessage = "The length of the string must be between 3 and 50 characters")]
        [Display(Name = "Nickname")]
        public string Nickname { get; set; }

        [Required]
        [DataType(DataType.Password)]
        [RegularExpression(@"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-+]).{8,20}$", ErrorMessage = @"Password should contains digit from 0-9, lowercase characters and uppercase characters, special symbols in the list #?!@$%^&*-+ and length at least 8 characters and maximum of 20")]
        [Display(Name = "Password")]
        public string Password { get; set; }

        [Compare("Password", ErrorMessage = "These passwords don't match!")]
        [DataType(DataType.Password)]
        [Display(Name = "Confirm password")]
        public string PasswordConfirm { get; set; }

        [Range(typeof(bool), "true", "true", ErrorMessage = "You dont agree to create an account!")]
        [Display(Name = "I agree to create an account")]
        public bool Agree { get; set; }
    }
}