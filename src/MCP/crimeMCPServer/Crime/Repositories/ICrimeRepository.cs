using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Crime.Repositories;

public interface ICrimeRepository
{
    Task<IEnumerable<Models.Crime>> GetCrimesAsync(string city, string description);
}
